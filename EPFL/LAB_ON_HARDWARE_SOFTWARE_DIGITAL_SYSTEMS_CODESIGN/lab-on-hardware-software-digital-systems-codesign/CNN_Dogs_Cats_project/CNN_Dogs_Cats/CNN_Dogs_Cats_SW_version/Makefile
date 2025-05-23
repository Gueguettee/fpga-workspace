all: cnnSolver

cnnSolver: cnnSolver.cpp model.cpp cnn.cpp model.h cnn.h
	g++ -O3 -Wall cnnSolver.cpp model.cpp cnn.cpp -o cnnSolver -lm

clean:
	rm -f cnnSolver

