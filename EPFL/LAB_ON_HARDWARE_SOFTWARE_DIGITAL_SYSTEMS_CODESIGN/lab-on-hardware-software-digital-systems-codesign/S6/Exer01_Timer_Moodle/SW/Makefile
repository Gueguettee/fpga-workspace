all: testTimer testTimerInterrupt

testTimer: testTimer.cpp
	g++ -O3 -Wall testTimer.cpp -o testTimer -lm -lcma -lpthread

testTimerInterrupt: testTimerInterrupt.cpp
	g++ -O3 -Wall testTimerInterrupt.cpp -o testTimerInterrupt -lm 

clean:
	rm -f testTimer
	rm -f testTimerInterrupt

