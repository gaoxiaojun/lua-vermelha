################################################################################
#
# (c) Copyright IBM Corp. 2016, 2016
#
#  This program and the accompanying materials are made available
#  under the terms of the Eclipse Public License v1.0 and
#  Apache License v2.0 which accompanies this distribution.
#
#      The Eclipse Public License is available at
#      http://www.eclipse.org/legal/epl-v10.html
#
#      The Apache License v2.0 is available at
#      http://www.opensource.org/licenses/apache2.0.php
#
# Contributors:
#    Multiple authors (IBM Corp.) - initial implementation and documentation
#
################################################################################

CC?= gcc
CXX?= g++

BUILD_CONFIG?= opt

ifeq ($(BUILD_CONFIG),debug)
	LUA_BUILD_CONFIG_FLAGS= -O0 -g
	VERMELHA_BUILD_CONFIG_FLAGS= -O0 -g
	JITBUILDER_BUILD_CONFIG_FLAGS= -O0 -g
	JITBUILDER_BUILD_CONFIG_VARS= BUILD_CONFIG=debug
else ifeq ($(BUILD_CONFIG),opt)
	LUA_BUILD_CONFIG_FLAGS= -O2 -g
	VERMELHA_BUILD_CONFIG_FLAGS= -O3 -g
	JITBUILDER_BUILD_CONFIG_LAGS= -O3 -g
	JITBUILDER_BUILD_CONFIG_VARS=
else ifeq ($(BUILD_CONFIG),prod)
	LUA_BUILD_CONFIG_FLAGS= -O2
	VERMELHA_BUILD_CONFIG_FLAGS= -O3
	JITBUILDER_BUILD_CONFIG_FLAGS= -O3
	JITBUILDER_BUILD_CONFIG_VARS= BUILD_CONFIG=prod ASSUMES=
endif

LUAV?= luav

LUA_APP?= lua.o
LUA_LIB?= liblua.a
VERMELHA_LIB?= libvermelha.a
JITBUILDER_LIB?= libjitbuilder.a

LUA_DIR?= $(PWD)/lua
VERMELHA_DIR?= $(PWD)/vermelha
JITBUILDER_DIR?= $(PWD)/omr/jitbuilder

LUA_LIBPATH?= $(LUA_DIR)/$(LUA_LIB)
VERMELHA_LIBPATH?= $(VERMELHA_DIR)/$(VERMELHA_LIB)
JITBUILDER_LIBPATH?= $(JITBUILDER_DIR)/release/$(JITBUILDER_LIB)


# targets

.PHONY: all $(LUA_DIR)/lua.o $(LUA_LIBPATH) $(VERMELHA_LIBPATH) $(JITBUILDER_LIBPATH)

all: $(LUAV)


$(LUAV): $(LUA_DIR)/lua.o $(LUA_LIBPATH) $(VERMELHA_LIBPATH) $(JITBUILDER_LIBPATH)
	$(CXX) -o $@ $(LUA_DIR)/lua.o $(LUA_LIBPATH) $(VERMELHA_LIBPATH) $(JITBUILDER_LIBPATH) -ldl -lm -Wl,-E -lreadline

$(LUA_DIR)/lua.o:
	cd $(LUA_DIR) && $(MAKE) lua.o SYSCFLAGS="-DLUA_USE_LINUX" MYCFLAGS="$(LUA_BUILD_CONFIG_FLAGS)"
$(LUA_LIBPATH):
	cd $(LUA_DIR) && $(MAKE) $(LUA_LIB) SYSCFLAGS="-DLUA_USE_LINUX" MYCFLAGS="$(LUA_BUILD_CONFIG_FLAGS)"

$(VERMELHA_LIBPATH):
	cd $(VERMELHA_DIR) && $(MAKE) $@ CXX="$(CXX)" CXX_FLAGS_EXTRA="-fpermissive -DLUA_C_LINKAGE $(VERMELHA_BUILD_CONFIG_FLAGS)"

$(JITBUILDER_LIBPATH):
	cd $(JITBUILDER_DIR) && $(MAKE) CXX="$(CXX)" CXX_FLAGS_EXTRA="$(JITBUILDER_BUILD_CONFIG_FLAGS)" $(JITBUILDER_BUILD_CONFIG_VARS)


# clean rules

clean:
	cd $(LUA_DIR) && $(MAKE) clean
	cd $(VERMELHA_DIR) && $(MAKE) clean

cleanlibs:
	rm -f $(LUA_DIR)/lua.o $(LUA_LIBPATH) $(VERMELHA_LIBPATH) $(JITBUILDER_LIBPATH)

cleanlua:
	cd $(LUA_DIR) && $(MAKE) clean

cleanvermelha:
	cd $(VERMELHA_DIR) && $(MAKE) cleanall

cleanjitbuilder:
	cd $(JITBUILDER_DIR) && $(MAKE) clean

cleanall:
	cd $(LUA_DIR) && $(MAKE) clean
	cd $(VERMELHA_DIR) && $(MAKE) cleanall
	cd $(JITBUILDER_DIR) && $(MAKE) clean

# lua patch

# version of lua to diff against
LUA?=luavm

# commit with the applied changes
COMMIT?=HEAD

PATCH_DEST?=$(PWD)
PATCH_FILE?=$(LUA)-$(COMMIT).patch

lua-patch:
	git diff $(LUA) $(COMMIT) -- lua/* > $(PATCH_DEST)/$(PATCH_FILE)

