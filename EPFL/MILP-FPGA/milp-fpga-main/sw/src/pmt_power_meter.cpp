#include "pmt_power_meter.h"

#include <pmt.h>

#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <mutex>
#include <stdexcept>
#include <sys/stat.h>
#include <thread>

namespace {

struct RailSpec {
  const char* env;
  const char* def_path;
  const char* name;
};

const RailSpec kRailSpecs[] = {
  {"PMT_PATH_CORE_LOGIC", "/sys/class/hwmon/hwmon0/power1_input", "CORE+LOGIC"},
  {"PMT_PATH_AUX",        "/sys/class/hwmon/hwmon1/power1_input", "AUX"},
  {"PMT_PATH_BOARD",      "/sys/class/hwmon/hwmon2/power1_input", "BOARD"},
};

const char* env_or(const char* var, const char* def) {
  const char* v = std::getenv(var);
  return (v && *v) ? v : def;
}

bool path_exists(const char* path) {
  struct stat st;
  return ::stat(path, &st) == 0;
}

}  // namespace

struct PmtPowerMeter::Impl {
  struct Rail {
    std::string                name;
    std::string                path;
    std::unique_ptr<pmt::PMT>  sensor;
    pmt::State                 t_start;
    pmt::State                 t_end;
    double                     energy_j = 0.0;
    double                     avg_w    = 0.0;
    double                     peak_w   = 0.0;
  };

  std::vector<Rail>            rails;
  std::vector<PmtRailReading>  public_rails;
  std::thread                  peak_thread;
  std::atomic<bool>            running{false};
  std::atomic<bool>            stop_flag{false};
  mutable std::mutex           mu;
  double                       window_s = 0.0;
};

PmtPowerMeter::PmtPowerMeter() : impl_(new Impl()) {}

PmtPowerMeter::~PmtPowerMeter() {
  if (impl_->running.load()) Stop();
}

bool PmtPowerMeter::Probe() {
  impl_->rails.clear();
  for (const auto& spec : kRailSpecs) {
    const char* path = env_or(spec.env, spec.def_path);
    if (!path_exists(path)) {
      std::fprintf(stderr,
                   "PmtPowerMeter: rail %s skipped — %s does not exist\n",
                   spec.name, path);
      continue;
    }
    Impl::Rail r;
    r.name = spec.name;
    r.path = path;
    try {
      r.sensor = pmt::Create("xilinx", path);
    } catch (const std::exception& e) {
      std::fprintf(stderr,
                   "PmtPowerMeter: pmt::Create(\"xilinx\", \"%s\") failed: %s\n",
                   path, e.what());
      continue;
    }
    if (!r.sensor) {
      std::fprintf(stderr,
                   "PmtPowerMeter: pmt::Create returned null for %s\n",
                   spec.name);
      continue;
    }
    impl_->rails.push_back(std::move(r));
  }
  // Populate the public view with names/paths so callers can list rails
  // immediately after Probe(); energy/avg/peak fill in at Stop().
  impl_->public_rails.clear();
  impl_->public_rails.reserve(impl_->rails.size());
  for (const auto& r : impl_->rails) {
    impl_->public_rails.push_back({r.name, r.path, 0.0, 0.0, 0.0});
  }
  return !impl_->rails.empty();
}

void PmtPowerMeter::Reset() {
  std::lock_guard<std::mutex> lk(impl_->mu);
  for (auto& r : impl_->rails) {
    r.energy_j = 0.0;
    r.avg_w    = 0.0;
    r.peak_w   = 0.0;
  }
  impl_->window_s = 0.0;
  impl_->public_rails.clear();
}

void PmtPowerMeter::Start(unsigned periodMs) {
  if (impl_->running.load()) return;
  if (impl_->rails.empty() && !Probe()) {
    std::fprintf(stderr, "PmtPowerMeter: no rails — energy will be 0\n");
    return;
  }
  Reset();

  for (auto& r : impl_->rails) r.t_start = r.sensor->Read();

  impl_->stop_flag.store(false);
  impl_->running.store(true);
  impl_->peak_thread = std::thread([this, periodMs]() {
    std::vector<pmt::State> prev(impl_->rails.size());
    for (size_t i = 0; i < impl_->rails.size(); ++i) prev[i] = impl_->rails[i].t_start;

    auto period = std::chrono::milliseconds(periodMs ? periodMs : 20);
    while (!impl_->stop_flag.load(std::memory_order_acquire)) {
      std::this_thread::sleep_for(period);
      std::lock_guard<std::mutex> lk(impl_->mu);
      for (size_t i = 0; i < impl_->rails.size(); ++i) {
        auto& r = impl_->rails[i];
        pmt::State cur = r.sensor->Read();
        double dt_s = pmt::PMT::seconds(prev[i], cur);
        if (dt_s > 0.0) {
          double w = pmt::PMT::watts(prev[i], cur);
          if (w > r.peak_w) r.peak_w = w;
        }
        prev[i] = cur;
      }
    }
  });
}

void PmtPowerMeter::Stop() {
  if (!impl_->running.load()) return;
  impl_->stop_flag.store(true, std::memory_order_release);
  if (impl_->peak_thread.joinable()) impl_->peak_thread.join();
  impl_->running.store(false);

  for (auto& r : impl_->rails) r.t_end = r.sensor->Read();

  std::lock_guard<std::mutex> lk(impl_->mu);
  if (!impl_->rails.empty()) {
    impl_->window_s = pmt::PMT::seconds(impl_->rails[0].t_start,
                                        impl_->rails[0].t_end);
  } else {
    impl_->window_s = 0.0;
  }

  impl_->public_rails.clear();
  impl_->public_rails.reserve(impl_->rails.size());
  for (auto& r : impl_->rails) {
    r.energy_j = pmt::PMT::joules(r.t_start, r.t_end);
    r.avg_w    = (impl_->window_s > 0.0) ? r.energy_j / impl_->window_s : 0.0;
    impl_->public_rails.push_back({r.name, r.path, r.energy_j, r.avg_w, r.peak_w});
  }
}

// BOARD is the ZCU104 total-input rail; CORE+LOGIC and AUX are PL sub-rails
// of it. Summing would double-count, so prefer BOARD when present.
double PmtPowerMeter::TotalEnergyJ() const {
  std::lock_guard<std::mutex> lk(impl_->mu);
  for (const auto& r : impl_->rails) {
    if (r.name == "BOARD") return r.energy_j;
  }
  double e = 0.0;
  for (const auto& r : impl_->rails) e += r.energy_j;
  return e;
}

double PmtPowerMeter::AvgPowerW() const {
  std::lock_guard<std::mutex> lk(impl_->mu);
  if (impl_->window_s <= 0.0) return 0.0;
  for (const auto& r : impl_->rails) {
    if (r.name == "BOARD") return r.avg_w;
  }
  double e = 0.0;
  for (const auto& r : impl_->rails) e += r.energy_j;
  return e / impl_->window_s;
}

double PmtPowerMeter::PeakPowerW() const {
  std::lock_guard<std::mutex> lk(impl_->mu);
  for (const auto& r : impl_->rails) {
    if (r.name == "BOARD") return r.peak_w;
  }
  double p = 0.0;
  for (const auto& r : impl_->rails) p += r.peak_w;
  return p;
}

double PmtPowerMeter::WindowSeconds() const {
  std::lock_guard<std::mutex> lk(impl_->mu);
  return impl_->window_s;
}

const std::vector<PmtRailReading>& PmtPowerMeter::Rails() const {
  return impl_->public_rails;
}
