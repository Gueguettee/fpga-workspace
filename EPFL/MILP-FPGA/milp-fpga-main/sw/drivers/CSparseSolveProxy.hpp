#ifndef CSPARSESOLVE_HPP
#define CSPARSESOLVE_HPP

#include <stdint.h>
#include "CAccelProxy.hpp"

class CSparseSolveProxy : public CAccelProxy {
  protected:
    struct TRegs {
      uint32_t control;             // 0x00
      uint32_t gier;                // 0x04
      uint32_t ier;                 // 0x08
      uint32_t isr;                 // 0x0c
      uint32_t input_l;             // 0x10
      uint32_t input_r;             // 0x14
      uint32_t padding0;            // 0x18
      uint32_t output_l;            // 0x1c
      uint32_t output_r;            // 0x20
      uint32_t padding1;            // 0x24
      uint32_t m;                   // 0x28
      uint32_t padding2;            // 0x2c
      uint32_t n;                   // 0x30
      uint32_t padding3;            // 0x34
      uint32_t nnz_A;               // 0x38
      uint32_t padding4;            // 0x3c
      uint32_t nnz_K;               // 0x40
      uint32_t padding5;            // 0x44
      uint32_t nnz_L;               // 0x48
      uint32_t padding6;            // 0x4c
      uint32_t mode;                // 0x50
      uint32_t padding7;            // 0x54
      uint32_t kform_iters;         // 0x58 (Read)
      uint32_t kform_iters_ctrl;    // 0x5c (ap_vld)
      uint32_t padding8;            // 0x60
      uint32_t padding9;            // 0x64
      uint32_t factor_iters;        // 0x68 (Read)
      uint32_t factor_iters_ctrl;   // 0x6c (ap_vld)
      uint32_t padding10;           // 0x70
      uint32_t padding11;           // 0x74
      uint32_t triangular_iters;    // 0x78 (Read)
      uint32_t triangular_iters_ctrl; // 0x7c (ap_vld)
    };

  public:
    enum Mode {
      MODE_SETUP = 0,   // load patterns only (cached on chip)
      MODE_SOLVE = 1,   // load D + b; full compute + dy
    };

    CSparseSolveProxy(bool Logging = false)
      : CAccelProxy(Logging) {}

    ~CSparseSolveProxy() {}

    uint32_t SparseSolve_HW(void *input, void *output,
                            uint32_t m, uint32_t n,
                            uint32_t nnz_A, uint32_t nnz_K, uint32_t nnz_L,
                            uint32_t mode = MODE_SOLVE,
                            uint32_t *kform_iters = nullptr,
                            uint32_t *factor_iters = nullptr,
                            uint32_t *triangular_iters = nullptr);
};

#endif  // CSPARSESOLVE_HPP
