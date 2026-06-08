"""Binary fixture format (SPLD/SPLF/SPLA/SPLI) for the sparse_solve testbench."""

from __future__ import annotations

import struct
from typing import BinaryIO

import numpy as np


MAGIC_TRISOLVE = 0x53504C44
MAGIC_FACTOR   = 0x53504C46
MAGIC_KFORM    = 0x53504C41
MAGIC_IPM      = 0x53504C49
VERSION = 1
DECIMALS = 40


def set_decimals(d: int) -> None:
    global DECIMALS
    if d < 1 or d > 126:
        raise ValueError(f"DECIMALS must be in [1, 126], got {d}")
    DECIMALS = d


def to_fxp_int(v: float) -> int:
    raw = int(round(float(v) * (1 << DECIMALS)))
    if raw < -(1 << 127) or raw >= (1 << 127):
        raise OverflowError(f"value {v} out of int128 range at Q*.{DECIMALS}")
    return raw


def write_int128_array(f: BinaryIO, arr: np.ndarray) -> None:
    if arr.dtype != np.float64:
        arr = arr.astype(np.float64)
    for v in arr:
        raw = to_fxp_int(float(v))
        u = raw & ((1 << 128) - 1)
        low  = u & 0xFFFFFFFFFFFFFFFF
        high = (u >> 64) & 0xFFFFFFFFFFFFFFFF
        f.write(struct.pack("<QQ", low, high))


def _write_with_pad(f: BinaryIO, arr: np.ndarray, dtype: str) -> None:
    raw = arr.astype(dtype).tobytes()
    f.write(raw)
    pad = (-len(raw)) & 3
    if pad:
        f.write(b"\x00" * pad)


def write_trisolve_fixture(path: str,
                           m: int,
                           L_colptr: np.ndarray,
                           L_rowidx_csc: np.ndarray,
                           L_values_csc: np.ndarray,
                           Dv: np.ndarray,
                           b: np.ndarray,
                           dy_expected: np.ndarray) -> None:
    nnz_L = int(L_colptr[-1])
    with open(path, "wb") as f:
        f.write(struct.pack("<IIII", MAGIC_TRISOLVE, VERSION, m, nnz_L))
        f.write(L_colptr.astype("<u4").tobytes())
        _write_with_pad(f, L_rowidx_csc, "<u2")
        write_int128_array(f, L_values_csc)
        write_int128_array(f, Dv)
        write_int128_array(f, b)
        f.write(dy_expected.astype("<f8").tobytes())


def write_kform_fixture(path: str,
                        m: int, n: int,
                        A_indptr: np.ndarray,
                        A_indices: np.ndarray,
                        A_values: np.ndarray,
                        D: np.ndarray,
                        K_colptr: np.ndarray,
                        K_rowidx: np.ndarray,
                        L_colptr: np.ndarray,
                        L_rowidx_csc: np.ndarray,
                        L_rowptr: np.ndarray,
                        L_colidx_csr: np.ndarray,
                        L_csc_pos: np.ndarray,
                        L_csr_pos: np.ndarray,
                        b: np.ndarray,
                        dy_expected: np.ndarray,
                        K_values_expected: np.ndarray) -> None:
    nnz_A = int(A_indptr[-1])
    nnz_K = int(K_colptr[-1])
    nnz_L = int(L_colptr[-1])
    with open(path, "wb") as f:
        f.write(struct.pack("<IIIIIII",
                            MAGIC_KFORM, VERSION, m, n, nnz_A, nnz_K, nnz_L))
        f.write(A_indptr.astype("<u4").tobytes())
        _write_with_pad(f, A_indices, "<u2")
        write_int128_array(f, A_values)
        write_int128_array(f, D)
        f.write(K_colptr.astype("<u4").tobytes())
        _write_with_pad(f, K_rowidx, "<u2")
        f.write(L_colptr.astype("<u4").tobytes())
        _write_with_pad(f, L_rowidx_csc, "<u2")
        f.write(L_rowptr.astype("<u4").tobytes())
        _write_with_pad(f, L_colidx_csr, "<u2")
        f.write(L_csc_pos.astype("<u4").tobytes())
        f.write(L_csr_pos.astype("<u4").tobytes())
        write_int128_array(f, b)
        f.write(dy_expected.astype("<f8").tobytes())
        f.write(K_values_expected.astype("<f8").tobytes())


def write_factor_fixture(path: str,
                         m: int,
                         K_colptr: np.ndarray,
                         K_rowidx: np.ndarray,
                         K_values: np.ndarray,
                         L_colptr: np.ndarray,
                         L_rowidx_csc: np.ndarray,
                         L_rowptr: np.ndarray,
                         L_colidx_csr: np.ndarray,
                         L_csc_pos: np.ndarray,
                         b: np.ndarray,
                         dy_expected: np.ndarray,
                         L_values_csc_expected: np.ndarray,
                         Dv_expected: np.ndarray) -> None:
    nnz_K = int(K_colptr[-1])
    nnz_L = int(L_colptr[-1])
    with open(path, "wb") as f:
        f.write(struct.pack("<IIIII", MAGIC_FACTOR, VERSION, m, nnz_K, nnz_L))
        f.write(K_colptr.astype("<u4").tobytes())
        _write_with_pad(f, K_rowidx, "<u2")
        write_int128_array(f, K_values)
        f.write(L_colptr.astype("<u4").tobytes())
        _write_with_pad(f, L_rowidx_csc, "<u2")
        f.write(L_rowptr.astype("<u4").tobytes())
        _write_with_pad(f, L_colidx_csr, "<u2")
        f.write(L_csc_pos.astype("<u4").tobytes())
        write_int128_array(f, b)
        f.write(dy_expected.astype("<f8").tobytes())
        f.write(L_values_csc_expected.astype("<f8").tobytes())
        f.write(Dv_expected.astype("<f8").tobytes())


def write_ipm_fixture(path: str,
                      m: int, n: int,
                      A_indptr: np.ndarray,
                      A_indices: np.ndarray,
                      A_values: np.ndarray,
                      K_colptr: np.ndarray,
                      K_rowidx: np.ndarray,
                      L_colptr: np.ndarray,
                      L_rowidx_csc: np.ndarray,
                      L_rowptr: np.ndarray,
                      L_colidx_csr: np.ndarray,
                      L_csc_pos: np.ndarray,
                      L_csr_pos: np.ndarray,
                      b: np.ndarray,
                      c: np.ndarray) -> None:
    nnz_A = int(A_indptr[-1])
    nnz_K = int(K_colptr[-1])
    nnz_L = int(L_colptr[-1])
    if A_values.shape[0] != nnz_A:
        raise ValueError(f"A_values length {A_values.shape[0]} != nnz_A {nnz_A}")
    if b.shape[0] != m:
        raise ValueError(f"b length {b.shape[0]} != m {m}")
    if c.shape[0] != n:
        raise ValueError(f"c length {c.shape[0]} != n {n}")
    with open(path, "wb") as f:
        f.write(struct.pack("<IIIIIII",
                            MAGIC_IPM, VERSION, m, n, nnz_A, nnz_K, nnz_L))
        f.write(A_indptr.astype("<u4").tobytes())
        _write_with_pad(f, A_indices, "<u2")
        write_int128_array(f, A_values)
        f.write(K_colptr.astype("<u4").tobytes())
        _write_with_pad(f, K_rowidx, "<u2")
        f.write(L_colptr.astype("<u4").tobytes())
        _write_with_pad(f, L_rowidx_csc, "<u2")
        f.write(L_rowptr.astype("<u4").tobytes())
        _write_with_pad(f, L_colidx_csr, "<u2")
        f.write(L_csc_pos.astype("<u4").tobytes())
        f.write(L_csr_pos.astype("<u4").tobytes())
        f.write(b.astype("<f8").tobytes())
        f.write(c.astype("<f8").tobytes())
