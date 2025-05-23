PROJECT_NAME = radioastro
MAKEFLAGS += " -j2 "
CFLAGS = -O3 -Wall
#CFLAGS = -O0 -Wall -g

# Set this to 1 to use CFFTProxy_kernel instead of CFFTProxy
USE_KERNEL ?= 0
CFLAGS += -DUSE_KERNEL=$(USE_KERNEL)

.PHONY: all clean

# Object list with conditional selection
COMMON_OBJS = obj/radioastro.o obj/signal_processing.o obj/utils.o obj/CAccelProxy.o obj/CAccelDriver.o obj/CXADCProxy.o
ifeq ($(USE_KERNEL), 1)
	FFT_OBJ = obj/CFFTProxy_kernel.o
else
	FFT_OBJ = obj/CFFTProxy.o
endif
OBJS = $(COMMON_OBJS) $(FFT_OBJ)

all: obj $(PROJECT_NAME)

$(PROJECT_NAME): $(OBJS) Makefile
	g++ $(CFLAGS) $(OBJS) -o $(PROJECT_NAME) -lcma -lpthread

obj/radioastro.o: src/radioastro.cpp src/signal_processing.h src/utils.h src/fxp_utils.h Makefile
	g++ -c $(CFLAGS) src/radioastro.cpp -o obj/radioastro.o

obj/signal_processing.o: src/signal_processing.cpp src/signal_processing.h src/utils.h src/fxp_utils.h Makefile
	g++ -c $(CFLAGS) src/signal_processing.cpp -o obj/signal_processing.o

obj/utils.o: src/utils.cpp src/utils.h Makefile
	g++ -c $(CFLAGS) src/utils.cpp -o obj/utils.o

obj/CAccelProxy.o: src/CAccelProxy.cpp src/CAccelProxy.hpp src/utils.h Makefile
	g++ -c $(CFLAGS) src/CAccelProxy.cpp -o obj/CAccelProxy.o

obj/CAccelDriver.o: src/CAccelDriver.cpp src/CAccelDriver.hpp src/utils.h Makefile
	g++ -c $(CFLAGS) src/CAccelDriver.cpp -o obj/CAccelDriver.o

obj/CXADCProxy.o: src/CXADCProxy.cpp src/CXADCProxy.hpp src/CAccelProxy.hpp src/utils.h Makefile
	g++ -c $(CFLAGS) src/CXADCProxy.cpp -o obj/CXADCProxy.o

obj/CFFTProxy.o: src/CFFTProxy.cpp src/CFFTProxy.hpp src/CAccelProxy.hpp src/utils.h Makefile
	g++ -c $(CFLAGS) src/CFFTProxy.cpp -o obj/CFFTProxy.o

obj/CFFTProxy_kernel.o: src/CFFTProxy_kernel.cpp src/CFFTProxy_kernel.hpp src/CAccelDriver.hpp src/utils.h Makefile
	g++ -c $(CFLAGS) src/CFFTProxy_kernel.cpp -o obj/CFFTProxy_kernel.o

obj:
	mkdir -p obj/

clean:
	rm -f $(PROJECT_NAME)
	rm -rf obj/
	rm -f sds_trace_data.dat
