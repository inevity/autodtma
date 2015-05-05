# Generated automatically from Makefile.in by configure.
SHELL=/bin/sh

srcdir = .
top_srcdir = ..
top_builddir = ..

prefix = /usr/local
bindir = ${exec_prefix}/bin
mandir = ${prefix}/man

CC = gcc
RANLIB = ranlib

INCLUDES = -I$(top_builddir) -I$(srcdir) -I$(top_srcdir) -I$(top_srcdir)/lib \
		-I$(top_srcdir)/gen $(SSL_INCLUDES)
DEFS = -DHAVE_CONFIG_H
CPPFLAGS =  -DNDEBUG -D_GNU_SOURCE -D_XOPEN_SOURCE
CFLAGS = -g -O2 -Wall
LDFLAGS = 
LIBS = -lm 

COMPILE = $(CC) -c $(DEFS) $(INCLUDES) $(CPPFLAGS) $(CFLAGS)
LINK = $(CC) $(LDFLAGS) -o $@



.c.o:
	$(COMPILE) $<

LIBSTAT_OBJS = basic.o sess_stat.o print_reply.o

all: libstat.a

libstat.a: $(LIBSTAT_OBJS)
	ar r $@ $(LIBSTAT_OBJS)
	$(RANLIB) $@

depend:

install:

clean:
	rm -f libstat.a $(LIBSTAT_OBJS)

distclean: clean
	rm -f *~

.PHONY: all install clean distclean depend
