MAKEFLAGS += " -j2 "
CFLAGS=-O2 -Wall

all: obj matMult multi_vector

multi_vector: obj/multi_vector.o obj/util.o
	g++ $(CFLAGS) obj/multi_vector.o obj/util.o -o multi_vector -lm

matMult: obj/matMult.o obj/util.o
	g++ $(CFLAGS) obj/matMult.o obj/util.o -o matMult -lm

obj/matMult.o: src/matMult.cpp src/util.hpp
	g++ -c $(CFLAGS) src/matMult.cpp -o obj/matMult.o
obj/util.o: src/util.cpp src/util.hpp
	g++ -c $(CFLAGS) src/util.cpp -o obj/util.o
obj/multi_vector.o: src/multi_vector.cpp src/util.hpp
	g++ -c $(CFLAGS) src/multi_vector.cpp -o obj/multi_vector.o

obj:
	mkdir obj/

clean:
	rm -f matMult multi_vector
	rm -rf obj/
