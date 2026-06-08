"""Host-side symbolic phase for sparse LDL^T of K = A diag(D) A^T."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
import scipy.sparse as sp
from scipy.sparse.csgraph import reverse_cuthill_mckee


@dataclass
class SparseSymbolic:
    m: int
    n: int

    P: np.ndarray
    P_inv: np.ndarray

    A_indptr: np.ndarray
    A_indices: np.ndarray
    A_values: np.ndarray

    K_colptr: np.ndarray
    K_rowidx: np.ndarray

    L_colptr: np.ndarray
    L_rowidx_csc: np.ndarray

    L_rowptr: np.ndarray
    L_colidx_csr: np.ndarray
    L_csc_pos: np.ndarray
    L_csr_pos: np.ndarray

    etree: np.ndarray


def _elimination_tree(K_lower_csc: sp.csc_matrix) -> np.ndarray:
    m = K_lower_csc.shape[0]
    parent = np.full(m, -1, dtype=np.int32)
    ancestor = np.full(m, -1, dtype=np.int32)

    K_upper = K_lower_csc.T.tocsc()
    indptr = K_upper.indptr
    indices = K_upper.indices

    for k in range(m):
        for p in range(indptr[k], indptr[k + 1]):
            i = int(indices[p])
            if i >= k:
                continue
            while True:
                a = int(ancestor[i])
                if a == -1:
                    ancestor[i] = k
                    parent[i] = k
                    break
                if a == k:
                    break
                ancestor[i] = k
                i = a
    return parent


def _l_pattern_up_looking(K_lower_csc: sp.csc_matrix,
                          parent: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    m = K_lower_csc.shape[0]

    K_upper = K_lower_csc.T.tocsc()
    Kt_indptr = K_upper.indptr
    Kt_indices = K_upper.indices

    col_rows: list[list[int]] = [[] for _ in range(m)]
    marker = np.full(m, -1, dtype=np.int32)

    for j in range(m):
        col_rows[j].append(j)
        marker[j] = j

        for p in range(Kt_indptr[j], Kt_indptr[j + 1]):
            i = int(Kt_indices[p])
            if i >= j:
                continue
            while i != -1 and marker[i] != j:
                marker[i] = j
                col_rows[i].append(j)
                i = int(parent[i])

    L_colptrs = [0]
    flat: list[int] = []
    for k in range(m):
        col_rows[k].sort()
        flat.extend(col_rows[k])
        L_colptrs.append(len(flat))

    L_colptr = np.asarray(L_colptrs, dtype=np.uint32)
    L_rowidx_csc = np.asarray(flat, dtype=np.uint16)
    return L_colptr, L_rowidx_csc


def _k_lower_pattern(A_perm_csr: sp.csr_matrix) -> sp.csc_matrix:
    A_pat = sp.csr_matrix(
        (np.ones(A_perm_csr.nnz, dtype=np.int32),
         A_perm_csr.indices, A_perm_csr.indptr),
        shape=A_perm_csr.shape,
    )
    K_pat_full = (A_pat @ A_pat.T).tocsc()
    K_pat_full.eliminate_zeros()
    K_pat_full.sum_duplicates()
    K_lower = sp.tril(K_pat_full, k=0).tocsc()
    K_lower.sort_indices()
    return K_lower


def prepare_sparse_problem(A: sp.spmatrix,
                           use_rcm: bool = True) -> SparseSymbolic:
    A_csr = A.tocsr().astype(np.float64)
    A_csr.sort_indices()
    m, n = A_csr.shape
    if m > 65535 or n > 65535:
        raise ValueError(f"m,n must be <= 65535 for uint16 indices; got {m},{n}")

    if use_rcm:
        AAT_pat = (A_csr.astype(bool).astype(np.int32) @
                   A_csr.astype(bool).astype(np.int32).T).tocsr()
        P = np.asarray(reverse_cuthill_mckee(AAT_pat, symmetric_mode=True),
                       dtype=np.int32)
    else:
        P = np.arange(m, dtype=np.int32)

    P_inv = np.empty_like(P)
    P_inv[P] = np.arange(m, dtype=np.int32)

    A_perm = A_csr[P, :]
    A_perm.sort_indices()

    K_lower = _k_lower_pattern(A_perm)

    parent = _elimination_tree(K_lower)
    L_colptr, L_rowidx_csc = _l_pattern_up_looking(K_lower, parent)

    L_rowptr, L_colidx_csr, L_csc_pos = _build_L_csr_view(m, L_colptr, L_rowidx_csc)

    L_csr_pos = np.empty(L_csc_pos.shape, dtype=np.uint32)
    L_csr_pos[L_csc_pos] = np.arange(L_csc_pos.size, dtype=np.uint32)

    return SparseSymbolic(
        m=m, n=n,
        P=P.astype(np.int32),
        P_inv=P_inv.astype(np.int32),
        A_indptr=A_perm.indptr.astype(np.uint32),
        A_indices=A_perm.indices.astype(np.uint16),
        A_values=A_perm.data.astype(np.float64),
        K_colptr=K_lower.indptr.astype(np.uint32),
        K_rowidx=K_lower.indices.astype(np.uint16),
        L_colptr=L_colptr,
        L_rowidx_csc=L_rowidx_csc,
        L_rowptr=L_rowptr,
        L_colidx_csr=L_colidx_csr,
        L_csc_pos=L_csc_pos,
        L_csr_pos=L_csr_pos,
        etree=parent.astype(np.int32),
    )


def _build_L_csr_view(m: int,
                      L_colptr: np.ndarray,
                      L_rowidx_csc: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    nnz_L = int(L_colptr[-1])
    row_count = np.zeros(m, dtype=np.uint32)
    for k in range(m):
        for p in range(int(L_colptr[k]), int(L_colptr[k + 1])):
            row_count[int(L_rowidx_csc[p])] += 1

    L_rowptr = np.zeros(m + 1, dtype=np.uint32)
    np.cumsum(row_count, out=L_rowptr[1:])

    L_colidx_csr = np.zeros(nnz_L, dtype=np.uint16)
    L_csc_pos = np.zeros(nnz_L, dtype=np.uint32)

    cursor = L_rowptr[:-1].astype(np.uint32).copy()
    for k in range(m):
        for p in range(int(L_colptr[k]), int(L_colptr[k + 1])):
            r = int(L_rowidx_csc[p])
            slot = int(cursor[r])
            L_colidx_csr[slot] = k
            L_csc_pos[slot] = p
            cursor[r] = slot + 1

    return L_rowptr, L_colidx_csr, L_csc_pos
