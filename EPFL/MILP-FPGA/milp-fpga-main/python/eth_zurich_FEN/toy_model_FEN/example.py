# -*- coding: utf-8 -*-
"""
Created on Mon Sep  9 14:27:49 2024

@author: Andrea Bellè, Research Center for Energy Networks (FEN) - ETH Zürich
"""

def test_example(vector_b,
                 vector_c,
                 vector_d,
                 vector_lhs,
                 vector_rhs,
                 matrix_A,
                 matrix_B,
                 integer_variables = True):
    
    '''    
    ===========================================================================
    
    Description: Solve the following minimization problem:
        
    
    min (b^T)x + (c^T)y + d
    s.t.        
    lhs <= Ax + By <= rhs        
    x \in R^N (real variables)
    y \in N^M or R^M  (integer or real variables)
    
    ===========================================================================    
    '''

    import gurobipy as gp
    from gurobipy import GRB
    import numpy as np
    
    print("Creating optimization problem ...")
    
    n_col_x = matrix_A.shape[1]
    n_col_y = matrix_B.shape[1]
            
    m = gp.Model("_")
        
    x = m.addMVar(shape=n_col_x, vtype=GRB.CONTINUOUS, name="x_",
                  lb = -np.infty, ub = np.infty)
    if integer_variables:
        y = m.addMVar(shape=n_col_y, vtype=GRB.INTEGER, name="y_",
                      lb = -np.infty, ub = np.infty)
    else:
        y = m.addMVar(shape=n_col_y, vtype=GRB.CONTINUOUS, name="y_",
                      lb = -np.infty, ub = np.infty)        
            
            
    m.setObjective(vector_b @ x + vector_c @ y + np.sum(vector_d), GRB.MINIMIZE)        
            
    lhs_arr = np.asarray(vector_lhs.todense()).flatten()
    rhs_arr = np.asarray(vector_rhs.todense()).flatten()

    n_rows = matrix_A.shape[0]
    chunk = 500_000
    for i in range(0, n_rows, chunk):
        sl = slice(i, min(i + chunk, n_rows))
        expr = matrix_A[sl] @ x + matrix_B[sl] @ y
        lhs = lhs_arr[sl]
        rhs = rhs_arr[sl]
        m.addConstr(expr >= lhs, name=f"LHS_{i}")
        m.addConstr(expr <= rhs, name=f"RHS_{i}")
        print(f"  Added constraints {i}–{min(i+chunk, n_rows)} / {n_rows}")      
    
    # m.setParam('Method', 2)
    # m.setParam('BarHomogeneous', -1)
    # m.setParam('BarConvTol', 1e-06)
    # m.setParam('Crossover', 1)
    # m.setParam('Threads', 4)
    # m.setParam('DualReductions', 1)  
    
    print("Solving optimization problem ...")
    
    m.optimize() 
    
    return m

# Load matrices and vectors
import os
from scipy import sparse

print("Reading data ...")

source_dir = os.path.join(os.path.dirname(__file__), "data")

file_matrix_A = "matrix_A.npz"
matrix_A = sparse.load_npz(os.path.join(source_dir, file_matrix_A))

file_matrix_B = "matrix_B.npz"
matrix_B = sparse.load_npz(os.path.join(source_dir, file_matrix_B))

file_vector_b = "vector_b.npz"
vector_b = sparse.load_npz(os.path.join(source_dir, file_vector_b))

file_vector_c = "vector_c.npz"
vector_c = sparse.load_npz(os.path.join(source_dir, file_vector_c))

file_vector_d = "vector_d.npz"
vector_d = sparse.load_npz(os.path.join(source_dir, file_vector_d))

file_vector_lhs = "vector_lhs.npz"
vector_lhs = sparse.load_npz(os.path.join(source_dir, file_vector_lhs))

file_vector_rhs = "vector_rhs.npz"
vector_rhs = sparse.load_npz(os.path.join(source_dir, file_vector_rhs))


# Solve optimization
if __name__ == "__main__":
    
    solved_model = test_example(vector_b,
                                vector_c,
                                vector_d,
                                vector_lhs,
                                vector_rhs,
                                matrix_A,
                                matrix_B,
                                integer_variables = True # Set to True for MILP, False for LP
                                )














