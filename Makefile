srcdir=.

CFLAGS=-g -O2 -I/usr/include/libpurple -I/usr/include/glib-2.0 -I/usr/lib64/glib-2.0/include  -Wall -Wextra -Wno-unused-parameter -I${srcdir} -I. -fno-strict-aliasing -fPIC -m64
LDFLAGS= -L/usr/lib -L/usr/lib  -lpurple -lglib-2.0  -lz -lm  -lcrypto -rdynamic -ggdb
CPPFLAGS= -I/usr/include -I/usr/include -DFLAGS -DPIC
COMPILE_FLAGS=${CFLAGS} ${CPPFLAGS}
LINK_FLAGS=${LDFLAGS}

CC=gcc

DEP=dep
AUTO=auto
EXE=bin
OBJ=objs
LIB=libs
DIR_LIST=${DEP} ${AUTO} ${EXE} ${OBJ} ${LIB} ${DEP}/auto ${OBJ}/auto


PLUGIN_OBJECTS=${OBJ}/telegram-purple.o ${OBJ}/tgp-net.o ${OBJ}/tgp-timers.o ${OBJ}/msglog.o ${OBJ}/telegram-base.o 

.SUFFIXES:

.SUFFIXES: .c .h .o

PRPL_LIBNAME=${EXE}/telegram-purple.so
all: ${PRPL_LIBNAME}

PLUGIN_DIR_PURPLE=$(shell pkg-config --variable=plugindir purple)
DATA_ROOT_DIR_PURPLE=$(shell pkg-config --variable=datarootdir purple)

include ${srcdir}/Makefile.tl-parser
include ${srcdir}/Makefile.tgl

create_dirs: ${DIR_LIST}
create_dirs_and_headers: ${DIR_LIST} ${AUTO}/auto.c ${AUTO}/auto-header.h ${AUTO}/constants.h

${DIR_LIST}:
	@test -d $@ || mkdir -p $@



${PLUGIN_OBJECTS}: ${OBJ}/%.o: ${srcdir}/%.c | create_dirs_and_headers
	echo $@ && ${CC} ${CFLAGS} ${CPPFLAGS} -I ${srcdir}/tgl -c -MP -MD -MF ${DEP}/$*.d -MQ ${OBJ}/$*.o -o $@ $<

${PRPL_LIBNAME}: ${PLUGIN_OBJECTS} ${LIB}/libtgl.a | create_dirs
	${CC} ${LDFLAGS} -shared $^ -o $@



.PHONY: plugin
plugin: $(PRPL_LIBNAME)


.PHONY: strip
strip: $(PRPL_LIBNAME)
	$(STRIP) --strip-unneeded $(PRPL_LIBNAME)

# TODO: Find a better place for server.pub
install: $(PRPL_LIBNAME)
	install -D $(PRPL_LIBNAME) $(DESTDIR)$(PLUGIN_DIR_PURPLE)/$(PRPL_LIBNAME)
	install -D tg-server.pub /etc/telegram-purple/server.pub
	install -D imgs/telegram16.png $(DESTDIR)$(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/16/telegram.png
	install -D imgs/telegram22.png $(DESTDIR)$(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/22/telegram.png
	install -D imgs/telegram48.png $(DESTDIR)$(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/48/telegram.png

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PLUGIN_DIR_PURPLE)/$(PRPL_LIBNAME)
	rm -f /etc/telegram-purple/server.pub
	rm -f $(DESTDIR)$(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/16/telegram.png
	rm -f $(DESTDIR)$(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/22/telegram.png
	rm -f $(DESTDIR)$(DATA_ROOT_DIR_PURPLE)/pixmaps/pidgin/protocols/48/telegram.png

.PHONY: run
run: install
	pidgin -d | grep 'telegram\|plugin\|proxy'

.PHONY: purge
purge: uninstall
	rm -rf $(HOME)/.telegram-purple

.PHONY: debug
debug: install
	ddd pidgin

clean:
	rm -rf ${DIR_LIST}  *.so *.a *.o telegram config.log config.status $(PRPL_C_OBJS) $(PRPL_LIBNAME) > /dev/null || echo "all clean"

