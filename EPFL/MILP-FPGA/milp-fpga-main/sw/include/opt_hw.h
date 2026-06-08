#ifndef OPT_HW_H
#define OPT_HW_H

#include "CAccelProxy.hpp"
#include "CDenseSolveProxy.hpp"
#include "fxp_utils.h"

#include "opt.h"

Result lp_solve_ipm_hw(const LPStd *M, const LPParams *p,
                       CDenseSolveProxy *solver,
                       TFXP *inputHW, TFXP *outputHW);

Result milp_solve_bnb_hw(const MILPStd *M, const LPParams *lp, const MILPParams *mp,
                         CDenseSolveProxy *solver,
                         TFXP *inputHW, TFXP *outputHW);

#endif // OPT_HW_H
