OCAMLC=ocamlc
OCAMLOPT=ocamlopt
OCAMLDEP=ocamldep

DESTDIR=`$(OCAMLC) -where`/ocamlmpi
PREFIX=$(shell find /usr/include /usr/local/include/ | grep -e "mpi\.h" | head -n 1 | xargs dirname | xargs dirname)
MPIINCDIR=$(PREFIX)/include/mpich2
MPILIBDIR=$(PREFIX)/lib
DOC_DIR = api-doc

CC=mpicc
CFLAGS=-I`$(OCAMLC) -where` -I$(MPIINCDIR) -O2 -g -Wall

COBJS=init.o comm.o msgs.o collcomm.o groups.o utils.o
OBJS=mpi.cmo

all: libcamlmpi.a byte

install:
	ocamlfind install mpi META mpi.mli mpi.cmi $(wildcard mpi.cm*a) $(wildcard *mpi.a)

libcamlmpi.a: $(COBJS)
	rm -f $@
	ar rc $@ $(COBJS)

byte: $(OBJS)
	$(OCAMLC) -a -o mpi.cma -custom $(OBJS) -cclib -lcamlmpi -ccopt -L$(MPILIBDIR) -cclib -lmpi

opt: $(OBJS:.cmo=.cmx)
	$(OCAMLOPT) -a -o mpi.cmxa $(OBJS:.cmo=.cmx) -cclib -lcamlmpi -ccopt -L$(MPILIBDIR) -cclib -lmpi

.SUFFIXES: .ml .mli .cmo .cmi .cmx

.ml.cmo:
	$(OCAMLC) -c $<
.mli.cmi:
	$(OCAMLC) -c $<
.ml.cmx:
	$(OCAMLOPT) -c $<

doc:
	mkdir -p $(DOC_DIR)
	ocamldoc -d $(DOC_DIR) -html mpi.mli

testmpi: test.ml mpi.cma libcamlmpi.a
	ocamlc -g -o testmpi unix.cma mpi.cma test.ml -ccopt -L.

testmpinb: testnb.ml mpi.cma libcamlmpi.a
	ocamlc -cc mpicc -g -o testmpinb unix.cma mpi.cma testnb.ml -ccopt -L.

clean::
	rm -f testmpi

test: testmpi
	mpirun -np 5 ./testmpi

test_mandel: test_mandel.ml mpi.cmxa libcamlmpi.a
	ocamlopt -o test_mandel graphics.cmxa mpi.cmxa test_mandel.ml -ccopt -L.

clean::
	rm -f test_mandel

clean::
	rm -f *.cm* *.o *.a
depend:
	$(OCAMLDEP) *.ml > .depend
	gcc -MM $(CFLAGS) *.c >> .depend

include .depend

clean::
	$(MAKE) -C test clean
