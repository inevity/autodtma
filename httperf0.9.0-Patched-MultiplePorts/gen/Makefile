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
		$(SSL_INCLUDES)
DEFS = -DHAVE_CONFIG_H
CPPFLAGS =  -DNDEBUG -D_GNU_SOURCE -D_XOPEN_SOURCE
CFLAGS = -g -O2 -Wall
LDFLAGS = 
LIBS = -lm 

COMPILE = $(CC) -c $(DEFS) $(INCLUDES) $(CPPFLAGS) $(CFLAGS)
LINK = $(CC) $(LDFLAGS) -o $@



.c.o:
	$(COMPILE) $<

LIBGEN_OBJS = call_seq.o conn_rate.o misc.o rate.o session.o \
	uri_fixed.o uri_wlog.o uri_wset.o \
	wsess.o wsesslog.o wsessreq.o wsesspage.o \
	sess_cookie.o

all: libgen.a

libgen.a: $(LIBGEN_OBJS)
	ar r $@ $(LIBGEN_OBJS)
	$(RANLIB) $@

depend:

install:

clean:
	rm -f libgen.a $(LIBGEN_OBJS)

distclean: clean
	rm -f *~

.PHONY: all install clean distclean depend
