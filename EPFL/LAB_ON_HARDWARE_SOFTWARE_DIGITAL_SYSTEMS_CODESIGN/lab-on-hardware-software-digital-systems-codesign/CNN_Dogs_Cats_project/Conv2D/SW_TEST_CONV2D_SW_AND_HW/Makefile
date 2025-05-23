all: conv2DTestbench

conv2DTestbench: conv2DTestbench.cpp CAccelDriver.hpp CAccelDriver.cpp CConv2DDriver.hpp CConv2DDriver.cpp util.hpp util.cpp
	g++ -O3 -Wall CAccelDriver.cpp CConv2DDriver.cpp util.cpp conv2DTestbench.cpp -o conv2DTestbench -lm -lcma -lpthread

clean:
	rm -f conv2DTestbench
