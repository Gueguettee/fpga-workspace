"""Sparse direct LDL^T Cholesky: host-side symbolic + numeric reference.

Used by:
- the FPGA SparseSolve kernel as the upstream "prepare problem" pass
  (one symbolic per problem, then per-IPM-iter the host ships D, b only)
- the HLS testbench as the golden numeric model
"""

from .utilities.symbolic import SparseSymbolic, prepare_sparse_problem
from .utilities.numeric_reference import numeric_factor_and_solve
