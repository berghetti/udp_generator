# SPDX-License-Identifier: BSD-3-Clause
# Copyright(c) 2010-2020 Intel Corporation

# binary name
APP = udp-generator

# all source are stored in SRCS-y
SRCS-y := $(wildcard ./src/*.c)

PKG_LIBDPDK=$(PWD)/dpdk/build/lib/x86_64-linux-gnu/pkgconfig/

PKGCONF=pkg-config

# Build using pkg-config variables if possible
ifneq ($(shell PKG_CONFIG_PATH=$(PKG_LIBDPDK) $(PKGCONF) --exists libdpdk && echo 0),0)
$(error "no installation of DPDK found.")
endif

all: static
.PHONY: shared static
shared: build/$(APP)-shared
	ln -sf $(APP)-shared build/$(APP)
static: build/$(APP)-static
	ln -sf $(APP)-static build/$(APP)

PC_FILE := $(shell PKG_CONFIG_PATH=$(PKG_LIBDPDK) $(PKGCONF) --path libdpdk 2>/dev/null)
CFLAGS += $(shell PKG_CONFIG_PATH=$(PKG_LIBDPDK) $(PKGCONF) --cflags libdpdk)
LDFLAGS_SHARED = $(shell PKG_CONFIG_PATH=$(PKG_LIBDPDK) $(PKGCONF) --libs libdpdk)
LDFLAGS_STATIC = $(shell PKG_CONFIG_PATH=$(PKG_LIBDPDK) $(PKGCONF) --static --libs libdpdk)

ifeq ($(MAKECMDGOALS),static)
# check for broken pkg-config
ifeq ($(shell echo $(LDFLAGS_STATIC) | grep 'whole-archive.*l:lib.*no-whole-archive'),)
$(warning "pkg-config output list does not contain drivers between 'whole-archive'/'no-whole-archive' flags.")
$(error "Cannot generate statically-linked binaries with this version of pkg-config")
endif
endif

CFLAGS += -Wall -Wextra -O3 -march=native
#CFLAGS +=-DDB

build/$(APP)-shared: $(SRCS-y) Makefile $(PC_FILE) | build
	$(CC) $(CFLAGS) $(filter %.c,$^) -o $@ $(LDFLAGS) $(LDFLAGS_SHARED) -lm

build/$(APP)-static: $(SRCS-y) Makefile $(PC_FILE) | build
	$(CC) $(CFLAGS) $(filter %.c,$^) -o $@ $(LDFLAGS) $(LDFLAGS_STATIC) -lm

build:
	@mkdir -p $@

.PHONY: clean
clean:
	rm -f build/$(APP) build/$(APP)-static build/$(APP)-shared
	test -d build && rmdir -p build || true
