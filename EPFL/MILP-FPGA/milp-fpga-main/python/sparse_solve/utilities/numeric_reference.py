"""Numeric golden model for sparse LDL^T of K = (P A) diag(D) (P A)^T."""

from __future__ import annotations

from typing import Tuple

import numpy as np
import scipy.sparse as sp

from .symbolic import SparseSymbolic


def _kij(symbolic: SparseSymbolic, D: np.ndarray, i: int, j: int) -> float:
    A_indptr = symbolic.A_indptr
    A_indices = symbolic.A_indices
    A_values = symbolic.A_values

    ia, ib = int(A_indptr[i]), int(A_indptr[i + 1])
    ja, jb = int(A_indptr[j]), int(A_indptr[j + 1])

    s = 0.0
    a, b = ia, ja
    while a < ib and b < jb:
        ca, cb = int(A_indices[a]), int(A_indices[b])
        if ca == cb:
            s += float(A_values[a]) * float(D[ca]) * float(A_values[b])
            a += 1; b += 1
        elif ca < cb:
            a += 1
        else:
            b += 1
    return s


def compute_K_values(symbolic: SparseSymbolic, D: np.ndarray) -> np.ndarray:
    K_colptr = symbolic.K_colptr
    K_rowidx = symbolic.K_rowidx
    nnz_K = int(K_colptr[-1])
    K_values = np.zeros(nnz_K, dtype=np.float64)
    m = symbolic.m
    for j in range(m):
        for p in range(int(K_colptr[j]), int(K_colptr[j + 1])):
            i = int(K_rowidx[p])
            K_values[p] = _kij(symbolic, D, i, j)
    return K_values


def factor_only(symbolic: SparseSymbolic,
                K_values: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    m = symbolic.m
    K_colptr = symbolic.K_colptr
    K_rowidx = symbolic.K_rowidx
    L_colptr = symbolic.L_colptr
    L_rowidx_csc = symbolic.L_rowidx_csc
    L_rowptr = symbolic.L_rowptr
    L_colidx_csr = symbolic.L_colidx_csr
    L_csc_pos = symbolic.L_csc_pos

    nnz_L = int(L_colptr[-1])
    L_values_csc = np.zeros(nnz_L, dtype=np.float64)
    Dv = np.zeros(m, dtype=np.float64)

    w = np.zeros(m, dtype=np.float64)
    flag = np.full(m, -1, dtype=np.int64)

    for j in range(m):
        diag = 0.0
        for p in range(int(K_colptr[j]), int(K_colptr[j + 1])):
            i = int(K_rowidx[p])
            v = float(K_values[p])
            if i == j:
                diag = v
            else:
                w[i] = v
                flag[i] = j

        rs, re = int(L_rowptr[j]), int(L_rowptr[j + 1])
        for q in range(rs, re):
            k = int(L_colidx_csr[q])
            if k >= j:
                continue
            l_jk = float(L_values_csc[int(L_csc_pos[q])])
            u = l_jk * Dv[k]
            diag -= l_jk * u

            for q2 in range(int(L_colptr[k]), int(L_colptr[k + 1])):
                r = int(L_rowidx_csc[q2])
                if r <= j:
                    continue
                if flag[r] != j:
                    w[r] = 0.0
                    flag[r] = j
                w[r] -= float(L_values_csc[q2]) * u

        if diag <= 0.0:
            diag = 1.0
        Dv[j] = diag
        inv_diag = 1.0 / diag

        for p in range(int(L_colptr[j]), int(L_colptr[j + 1])):
            r = int(L_rowidx_csc[p])
            if r == j:
                L_values_csc[p] = 1.0
            else:
                v = w[r] if flag[r] == j else 0.0
                L_values_csc[p] = v * inv_diag

    return L_values_csc, Dv


def solve_only(symbolic: SparseSymbolic,
               L_values_csc: np.ndarray,
               Dv: np.ndarray,
               b_perm: np.ndarray) -> np.ndarray:
    m = symbolic.m
    L_colptr = symbolic.L_colptr
    L_rowidx_csc = symbolic.L_rowidx_csc

    z = b_perm.astype(np.float64).copy()
    for j in range(m):
        zj = z[j]
        for p in range(int(L_colptr[j]) + 1, int(L_colptr[j + 1])):
            z[int(L_rowidx_csc[p])] -= float(L_values_csc[p]) * zj

    y = z / Dv

    dy = y.copy()
    for j in range(m - 1, -1, -1):
        s = dy[j]
        for p in range(int(L_colptr[j]) + 1, int(L_colptr[j + 1])):
            s -= float(L_values_csc[p]) * dy[int(L_rowidx_csc[p])]
        dy[j] = s
    return dy


def numeric_factor_and_solve(symbolic: SparseSymbolic,
                             D: np.ndarray,
                             b: np.ndarray) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    m = symbolic.m
    n = symbolic.n
    if D.shape != (n,):
        raise ValueError(f"D must be ({n},), got {D.shape}")
    if b.shape != (m,):
        raise ValueError(f"b must be ({m},), got {b.shape}")
    if np.any(D <= 0):
        raise ValueError("D must be strictly positive")

    K_values = compute_K_values(symbolic, D)
    L_values_csc, Dv = factor_only(symbolic, K_values)

    b_perm = b[symbolic.P]
    dy_perm = solve_only(symbolic, L_values_csc, Dv, b_perm)

    dy = np.empty(m, dtype=np.float64)
    dy[symbolic.P] = dy_perm
    return dy, L_values_csc, Dv


def assemble_K(symbolic: SparseSymbolic, D: np.ndarray) -> sp.csc_matrix:
    A_perm = sp.csr_matrix(
        (symbolic.A_values, symbolic.A_indices, symbolic.A_indptr),
        shape=(symbolic.m, symbolic.n),
    )
    Dmat = sp.diags(D)
    K = (A_perm @ Dmat @ A_perm.T).tocsc()
    K.eliminate_zeros()
    return K
