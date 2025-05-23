// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2022.2 (64-bit)
// Tool Version Limit: 2019.12
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// ==============================================================
// control
// 0x00 : Control signals
//        bit 0  - ap_start (Read/Write/COH)
//        bit 1  - ap_done (Read/COR)
//        bit 2  - ap_idle (Read)
//        bit 3  - ap_ready (Read/COR)
//        bit 7  - auto_restart (Read/Write)
//        bit 9  - interrupt (Read)
//        others - reserved
// 0x04 : Global Interrupt Enable Register
//        bit 0  - Global Interrupt Enable (Read/Write)
//        others - reserved
// 0x08 : IP Interrupt Enable Register (Read/Write)
//        bit 0 - enable ap_done interrupt (Read/Write)
//        bit 1 - enable ap_ready interrupt (Read/Write)
//        others - reserved
// 0x0c : IP Interrupt Status Register (Read/TOW)
//        bit 0 - ap_done (Read/TOW)
//        bit 1 - ap_ready (Read/TOW)
//        others - reserved
// 0x10 : Data signal of ap_return
//        bit 31~0 - ap_return[31:0] (Read)
// 0x18 : Data signal of numDBEntries
//        bit 31~0 - numDBEntries[31:0] (Read/Write)
// 0x1c : reserved
// 0x20 : Data signal of numSeqsSpecimen
//        bit 31~0 - numSeqsSpecimen[31:0] (Read/Write)
// 0x24 : reserved
// 0x28 : Data signal of seqsDB
//        bit 31~0 - seqsDB[31:0] (Read/Write)
// 0x2c : reserved
// 0x30 : Data signal of seqsSpecimen
//        bit 31~0 - seqsSpecimen[31:0] (Read/Write)
// 0x34 : reserved
// 0x38 : Data signal of lengthsDB
//        bit 31~0 - lengthsDB[31:0] (Read/Write)
// 0x3c : reserved
// 0x40 : Data signal of lengthsSpecimen
//        bit 31~0 - lengthsSpecimen[31:0] (Read/Write)
// 0x44 : reserved
// 0x48 : Data signal of scores
//        bit 31~0 - scores[31:0] (Read/Write)
// 0x4c : reserved
// (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)

#define XSEQMATCHER_HW_CONTROL_ADDR_AP_CTRL              0x00
#define XSEQMATCHER_HW_CONTROL_ADDR_GIE                  0x04
#define XSEQMATCHER_HW_CONTROL_ADDR_IER                  0x08
#define XSEQMATCHER_HW_CONTROL_ADDR_ISR                  0x0c
#define XSEQMATCHER_HW_CONTROL_ADDR_AP_RETURN            0x10
#define XSEQMATCHER_HW_CONTROL_BITS_AP_RETURN            32
#define XSEQMATCHER_HW_CONTROL_ADDR_NUMDBENTRIES_DATA    0x18
#define XSEQMATCHER_HW_CONTROL_BITS_NUMDBENTRIES_DATA    32
#define XSEQMATCHER_HW_CONTROL_ADDR_NUMSEQSSPECIMEN_DATA 0x20
#define XSEQMATCHER_HW_CONTROL_BITS_NUMSEQSSPECIMEN_DATA 32
#define XSEQMATCHER_HW_CONTROL_ADDR_SEQSDB_DATA          0x28
#define XSEQMATCHER_HW_CONTROL_BITS_SEQSDB_DATA          32
#define XSEQMATCHER_HW_CONTROL_ADDR_SEQSSPECIMEN_DATA    0x30
#define XSEQMATCHER_HW_CONTROL_BITS_SEQSSPECIMEN_DATA    32
#define XSEQMATCHER_HW_CONTROL_ADDR_LENGTHSDB_DATA       0x38
#define XSEQMATCHER_HW_CONTROL_BITS_LENGTHSDB_DATA       32
#define XSEQMATCHER_HW_CONTROL_ADDR_LENGTHSSPECIMEN_DATA 0x40
#define XSEQMATCHER_HW_CONTROL_BITS_LENGTHSSPECIMEN_DATA 32
#define XSEQMATCHER_HW_CONTROL_ADDR_SCORES_DATA          0x48
#define XSEQMATCHER_HW_CONTROL_BITS_SCORES_DATA          32

