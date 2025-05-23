all: VectorAdder

VectorAdder: VectorAdder.cpp CAccelDriver.cpp CAccelDriver.hpp CVectorAdderDriver.hpp CVectorAdderDriver.cpp util.cpp util.cpp
	g++ -O3 -Wall CAccelDriver.cpp CVectorAdderDriver.cpp util.cpp VectorAdder.cpp -o VectorAdder -lm -lcma -lpthread

clean:
	rm -f VectorAdder
