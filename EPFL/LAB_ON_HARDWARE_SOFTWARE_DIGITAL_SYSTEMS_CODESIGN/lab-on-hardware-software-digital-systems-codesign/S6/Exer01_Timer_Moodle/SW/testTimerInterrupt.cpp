#include <stdio.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

const char * DRIVER_NAME = "/dev/testtimer";

int main(int argc, char ** argv)
{
  int driver;

  printf("\n\nThis program requires that the TimerInterrupt bitstream is loaded in the FPGA.\n");
  printf("This program requires that the driver is loaded in the sistem. Don't use sudo!\n");
  printf("Press ENTER to confirm that the bitstream is loaded (proceeding without it can crash the board).\n\n");
  getchar();

	// Open the device driver
  driver = open(DRIVER_NAME, O_RDWR);
  if (driver == -1) {
    printf("ERR: cannot open driver %s\n", DRIVER_NAME);
    return -1;
  }
  printf("Driver %s opened successfully\n", DRIVER_NAME);
  srand(time(NULL));

  uint32_t count = 0;
  while(1){
    int32_t waitPeriod = rand() % 10;
    int32_t readBytes = read(driver, (void *)&count, sizeof(count));
    if (readBytes != sizeof(count))
      printf("Warning! Read %d bytes instead than %d\n", readBytes, sizeof(count));
    printf("Elapsed %u seconds. Now, going to sleep %d seconds...\n", count, waitPeriod);
    sleep(waitPeriod);
  }

  close(driver);

	return 0;
}

