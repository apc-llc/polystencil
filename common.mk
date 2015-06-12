#
# common Makefile
#
# Gets included after the local Makefile in an example sub-directory
#

CC ?= gcc

PLC ?= polycc

LIKWID ?= -I../../likwid/3.1.1/include -DLIKWID -DLIKWID_PERFMON -DDP=1 -DUSE_LIKWID -L/apps/likwid/3.1.1/lib -llikwid

ifeq ($(CC), gcc)
	OPT_FLAGS := -O3 -ffast-math -march=native -fopenmp $(LIKWID)
	PAR_FLAGS := -ftree-parallelize-loops=4
	OMP_FLAGS := -fopenmp
	VEC       := -ftree-vectorize -ftree-vectorizer-verbose=1
	NOVEC     := -fno-tree-vectorize
else
ifeq ($(CC), icc)
	OPT_FLAGS := -Ofast -openmp -xHOST -fno-alias
	PAR_FLAGS := -parallel
	OMP_FLAGS := -openmp
	VEC       := -vec_report=2
	NOVEC     := -no-vec -no-simd
else
ifeq ($(CC), ppcg)
	# TODO
else
	$(error Unsupported compiler $(CC))
endif
endif
endif

CFLAGS += -DTIME
PLCFLAGS += --islsolve
TILEFLAGS += 

ifdef PERFCTR
	CFLAGS += -DPERFCTR -lpapi
endif

all: orig orig_novec tiled tiled_par lbpar lbpar_novec  

$(SRC).tiled.c: $(SRC).c
	$(PLC) $< --tile $(TILEFLAGS) $(PLCFLAGS) -o $@

$(SRC).par.c: $(SRC).c
	$(PLC) $< --tile --parallel $(TILEFLAGS) $(PLCFLAGS)  -o $@

$(SRC).lbpar.c: $(SRC).c
	$(PLC) $< --tile --parallel --partlbtile $(TILEFLAGS) $(PLCFLAGS) -o $@

orig: $(SRC).c 
	$(CC) $(OPT_FLAGS) $(CFLAGS) $< $(VEC) -o $@ $(LDFLAGS)

orig_novec: $(SRC).c 
	$(CC) $(OPT_FLAGS) $(CFLAGS) $< $(NOVEC) -o $@ $(LDFLAGS)

orig_par: $(SRC).c
	$(CC) $(OPT_FLAGS) $(CFLAGS) $(PAR_FLAGS) $< $(VEC) -o $@ $(LDFLAGS)

opt: $(SRC).opt.c
	$(CC) $(OPT_FLAGS) $(CFLAGS) $< $(VEC) -o $@ $(LDFLAGS)

tiled: $(SRC).tiled.c 
	$(CC) $(OPT_FLAGS) $(CFLAGS) $< $(VEC) -o $@ $(LDFLAGS)

lbpar: $(SRC).lbpar.c
	$(CC) $(OPT_FLAGS) $(CFLAGS) $(OMP_FLAGS) $< $(VEC) -o $@ $(LDFLAGS)

lbpar_novec: $(SRC).lbpar.c
	$(CC) $(OPT_FLAGS) $(CFLAGS) $(OMP_FLAGS) $< $(NOVEC) -o $@ $(LDFLAGS)

tiled_par: $(SRC).par.c
	$(CC) $(OPT_FLAGS) $(CFLAGS) $(OMP_FLAGS) $< $(VEC) -o $@ $(LDFLAGS)

patus: $(SRC).patus.c patus_dir/kernel.stc
	$(MAKE) --directory=patus_dir
	$(CC) $(OPT_FLAGS) $(CFLAGS) $(OMP_FLAGS) $(SRC).patus.c patus_dir/kernel/kernel.c  $(VEC) -o $@  $(LDFLAGS)

perf: orig tiled par orig_par
	rm -f .test
	./orig
	OMP_NUM_THREADS=4 ./orig_par
	./tiled
	OMP_NUM_THREADS=4 ./par 


test: orig tiled par
	touch .test
	./orig 2> out_orig
	./tiled 2> out_tiled
	diff -q out_orig out_tiled
	OMP_NUM_THREADS=$(NTHREADS) ./par 2> out_par4
	rm -f .test
	diff -q out_orig out_par4
	@echo Success!

lbtest: par lbpar
	touch .test
	OMP_NUM_THREADS=$(NTHREADS) ./par 2> out_par4
	OMP_NUM_THREADS=$(NTHREADS) ./lbpar 2> out_lbpar4
	rm -f .test
	diff -q out_par4 out_lbpar4
	@echo Success!

opt-test: orig opt
	touch .test
	./orig > out_orig
	./opt > out_opt
	rm -f .test
	diff -q out_orig out_opt
	@echo Success!
	rm -f .test

clean:
	rm -f orig_novec out *.optrpt lbpar_novec out_* opt orig orig_no tiled lbtile lbpar lbpar_no  orig opt tiled par sched orig_par \
		hopt hopt *.par2d.c *.out.* \
		*.kernel.* a.out $(EXTRA_CLEAN) tags tmp* gmon.out *~ .unroll \
	   	.vectorize par2d parsetab.py *.body.c *.pluto.c *.par.cloog *.tiled.cloog *.pluto.cloog
	make exec-clean

realclean:
	rm -f  out_* opt orig orig_no out_* *.lbpar.c *.tiled.c *.opt.c *.par.c orig opt tiled par sched orig_par \
		hopt hopt *.par2d.c *.out.* \
		*.kernel.* a.out $(EXTRA_CLEAN) tags tmp* gmon.out *~ .unroll \
	   	.vectorize par2d parsetab.py *.body.c *.pluto.c *.par.cloog *.tiled.cloog *.pluto.cloog

exec-clean:
	rm -f out_* lbpar_novec opt orig orig_no tiled lbtile lbpar lbpar_no orig_novec sched sched hopt hopt tiled_par orig_par *.out.* *.kernel.* a.out \
		$(EXTRA_CLEAN) tags tmp* gmon.out *~ par2d
