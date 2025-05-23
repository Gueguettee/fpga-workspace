all: cnnSolver

cnnSolver: cnnSolver.cpp model.cpp cnn.cpp CAccelDriver.cpp CConv2DDriver.cpp util.hpp util.cpp
	g++ -O3 -Wall CAccelDriver.cpp CConv2DDriver.cpp util.cpp model.cpp cnn.cpp cnnSolver.cpp -o cnnSolver -lm -lcma -lpthread

clean:
	rm -f cnnSolver
