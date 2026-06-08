#ifndef PMT_POWER_METER_H
#define PMT_POWER_METER_H
// ZCU104 power meter over the ASTRON PMT toolkit. PMT's "xilinx" backend is a
// generic /sys/class/hwmon/.../power*_input reader despite the name. Default
// rails (override via the named env vars):
//   CORE+LOGIC -> /sys/class/hwmon/hwmon0/power1_input  (PMT_PATH_CORE_LOGIC)
//   AUX        -> /sys/class/hwmon/hwmon1/power1_input  (PMT_PATH_AUX)
//   BOARD      -> /sys/class/hwmon/hwmon2/power1_input  (PMT_PATH_BOARD)

#include <memory>
#include <string>
#include <vector>

struct PmtRailReading {
  std::string name;
  std::string path;
  double      energy_j;
  double      avg_w;
  double      peak_w;
};

class PmtPowerMeter {
public:
  PmtPowerMeter();
  ~PmtPowerMeter();

  // Detect rails. Returns false if none of the three configured paths exist
  // or PMT failed to attach. Safe to call before Start().
  bool Probe();

  // Begin sampling at periodMs (default 20 ms = 50 Hz peak polling).
  // PMT itself reads on demand; this thread is what tracks per-rail peak.
  void Start(unsigned periodMs = 20);

  // Stop the peak thread and finalize energy/avg/window.
  void Stop();

  // Reset accumulators (does not re-Probe rails).
  void Reset();

  // Aggregates over the last Start/Stop window. Returns the BOARD rail when
  // present; otherwise sums across rails. Use Rails() for the breakdown.
  double TotalEnergyJ() const;
  double AvgPowerW()    const;
  double PeakPowerW()   const;
  double WindowSeconds() const;

  // Per-rail breakdown (populated after Stop()).
  const std::vector<PmtRailReading>& Rails() const;

private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};

#endif // PMT_POWER_METER_H
