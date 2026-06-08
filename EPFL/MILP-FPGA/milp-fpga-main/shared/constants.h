#ifndef CONSTANTS_H
#define CONSTANTS_H

// ── Fixed-point Q-format split ───────────────────────────────────────────────
// Q(Q_INT_BITS).(Q_FRAC_BITS) signed. Total TFXP width = 1 + Q_INT_BITS +
// Q_FRAC_BITS (must equal 72). Override at build time with
//   -DQ_INT_BITS=<n> -DQ_FRAC_BITS=<m>
// to sweep Q-formats without editing this file.
#ifndef Q_INT_BITS
#define Q_INT_BITS 31
#endif
#ifndef Q_FRAC_BITS
#define Q_FRAC_BITS 40
#endif

#define DENSE_MAX_M_POWER 8
#define DENSE_MAX_M 256
#define DENSE_MAX_N_POWER DENSE_MAX_M_POWER
#define DENSE_MAX_N 256
#define DENSE_MAX_MN (DENSE_MAX_M * DENSE_MAX_N)

#define SPARSE_MAX_M       8192
#define SPARSE_MAX_N       8192
#define SPARSE_MAX_NNZ_A   65536
#define SPARSE_MAX_NNZ_K   65536
#define SPARSE_L_ON_CHIP_MAX_NNZ 65536
#define SPARSE_MAX_NNZ_L   SPARSE_L_ON_CHIP_MAX_NNZ
#ifndef SPARSE_UNROLL
#define SPARSE_UNROLL      16
#endif

#endif // CONSTANTS_H
