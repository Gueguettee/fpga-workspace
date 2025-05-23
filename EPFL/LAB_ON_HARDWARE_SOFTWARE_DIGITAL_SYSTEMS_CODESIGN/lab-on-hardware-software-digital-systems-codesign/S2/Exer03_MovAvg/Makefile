all: testMovingAvg

testMovingAvg: testMovingAvg.cpp util.hpp util.cpp
	g++ -O3 -Wall testMovingAvg.cpp util.cpp -o testMovingAvg -lm -lcma -lpthread

clean:
	rm -f testMovingAvg
