https://www.fen.ethz.ch/

##############################################################################################

This example represents a multi-energy investment planning with a single investment period.


The problem presents the following form:

##############################################################################################

min_{x, y} (b^T)x + (c^T)y + d

s.t.

lhs <= Ax + By <= rhs

x \in R^N (N operational variables, real domain)

y \in N^M or R^M  (M investment variables, integer or real domain)

##############################################################################################

This specific example contains 9942629 operational variables (|x| = N = 9942629), 656 investment variables (|y| = M = 656), and 39453744 constraints.

Computational performance on a laptop with Intel® Core™ i7-1355U Processor and 32 GB RAM:

Problem solved as LP: around 300 seconds (5 minutes).

Problem solved as MILP: around 3000 seconds (50 minutes).







 