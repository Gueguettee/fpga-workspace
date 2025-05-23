all: SimpleAdder

SimpleAdder: SimpleAdder.cpp CAccelDriver.cpp CAccelDriver.hpp CSimpleAdderDriver.hpp CSimpleAdderDriver.cpp util.cpp util.cpp
	g++ -O3 -Wall CAccelDriver.cpp CSimpleAdderDriver.cpp util.cpp SimpleAdder.cpp -o SimpleAdder -lm -lcma -lpthread

clean:
	rm -f SimpleAdder
