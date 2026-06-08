#ifndef CHOLESKY_SOLVE_LOCAL_H
#define CHOLESKY_SOLVE_LOCAL_H

#include "fxp_utils.h"
#include "constants.h"
#include "hls_stream.h"

void cholesky_solve_hw(uint32_t m, hls::stream<TFXP> &k_col_stream, TFXP b[], TFXP dy[]);

#endif // CHOLESKY_SOLVE_LOCAL_H
