#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <map>
#include "util.hpp"
#include "CAccelDriver.hpp"
#include "CSeqMatcherDriver.hpp"

uint32_t CSeqMatcherDriver::SeqMatcher_HW(uint32_t numDBEntries, uint32_t numSeqsSpecimen,
    void * seqsDB, void * seqsSpecimen, void * lengthsDB, void * lengthsSpecimen,
    void * scores, uint32_t &numComparisons)
{
  volatile TRegs * regs = (TRegs*)accelRegs;
  uint32_t phySeqsDB, phySeqsSpecimen, phyLengthsDB, phyLengthsSpecimen, phyScores;
  uint32_t status;

  if (logging)
    printf("CSeqMatcherDriver::SeqMatcher_HW(numDBEnttries=%u, numSeqsSpecimen=%u, seqsDB=0x%08X, seqsSpecimen=0x%08X, "
          "lengtsDB=0x%08X, lengthsSpecimen=0x%08X, scores=0x%08X\n", 
          (uint32_t)numDBEntries, (uint32_t)numSeqsSpecimen, (uint32_t)seqsDB, (uint32_t)seqsSpecimen,
          (uint32_t)lengthsDB, (uint32_t)lengthsSpecimen, (uint32_t)scores);

  if (accelRegs == NULL) {
    if (logging)
      printf("Error: Calling SeqMatcher_HW() on a non-initialized accelerator.\n");
    return DEVICE_NOT_INITIALIZED;
  }

  // We need to obtain the physical addresses corresponding to each of the virtual addresses passed by the application.
  // The accelerator uses only the physical addresses (and only contiguous memory).
  phySeqsDB = GetDMAPhysicalAddr(seqsDB);
  if (phySeqsDB == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)seqsDB);
    return VIRT_ADDR_NOT_FOUND;
  }
  phySeqsSpecimen = GetDMAPhysicalAddr(seqsSpecimen);
  if (phySeqsSpecimen == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)seqsSpecimen);
    return VIRT_ADDR_NOT_FOUND;
  }
  phyLengthsDB = GetDMAPhysicalAddr(lengthsDB);
  if (phyLengthsDB == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)lengthsDB);
    return VIRT_ADDR_NOT_FOUND;
  }
  phyLengthsSpecimen = GetDMAPhysicalAddr(lengthsSpecimen);
  if (phyLengthsSpecimen == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)lengthsSpecimen);
    return VIRT_ADDR_NOT_FOUND;
  }
  phyScores = GetDMAPhysicalAddr(scores);
  if (phyScores == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)scores);
    return VIRT_ADDR_NOT_FOUND;
  }

  regs->numDBEntries = numDBEntries;
  regs->numSeqsSpecimen = numSeqsSpecimen;
  regs->seqsDB = phySeqsDB;
  regs->seqsSpecimen = phySeqsSpecimen;
  regs->lengthsDB = phyLengthsDB;
  regs->lengthsSpecimen = phyLengthsSpecimen;
  regs->scores = phyScores;

  if (logging)
    printf("\nStarting accel...\n");

  status = regs->control;
  status |= 1;  // Set to 1 ap_start
  regs->control = status;

  do {
    status = regs->control;
    usleep(1000);
  } while ( ( (status & 2) != 2) ); // wait until ap_done==1

  numComparisons = regs->returnValue;

  return OK;
}


