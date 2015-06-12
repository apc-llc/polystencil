COMPILERS = gcc icc polycc pluto

.PHONY: $(COMPILERS)

all: $(COMPILERS)

gcc:
	cd heat-2d && CC=gcc $(MAKE)

clean:
	cd heat-2d && $(MAKE) clean
