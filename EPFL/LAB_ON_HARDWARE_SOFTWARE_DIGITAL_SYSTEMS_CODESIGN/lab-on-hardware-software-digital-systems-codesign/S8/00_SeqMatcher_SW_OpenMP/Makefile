PROJECT_NAME = seqMatcher
MAKEFLAGS += " -j2 "
CFLAGS = -O3 -Wall -fopenmp -lpthread -DNUM_THREADS=2
#CFLAGS = -O0 -Wall -g
.PHONY: all

all: $(PROJECT_NAME)

$(PROJECT_NAME): $(PROJECT_NAME).cpp $(PROJECT_NAME).h main.cpp util.cpp Makefile
	g++ $(CFLAGS) -o $(PROJECT_NAME) $(PROJECT_NAME).cpp main.cpp util.cpp


clean:
	rm -f $(PROJECT_NAME)
	#rm -f $(PROJECT_NAME).o
