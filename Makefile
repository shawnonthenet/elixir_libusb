ifeq ($(ERL_EI_INCLUDE_DIR),)
ERL_ROOT_DIR = $(shell erl -eval "io:format(\"~s~n\", [code:root_dir()])" -s init stop -noshell)
ifeq ($(ERL_ROOT_DIR),)
   $(error Could not find the Erlang installation. Check to see that 'erl' is in your PATH)
endif
ERL_EI_INCLUDE_DIR = "$(ERL_ROOT_DIR)/usr/include"
ERL_EI_LIBDIR = "$(ERL_ROOT_DIR)/usr/lib"
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)

# NIF_CFLAGS := -O2 -flat_namespace -undefined suppress
# NIF_LDFLAGS := -fPIC -shared -pedantic
LDFLAGS += -fPIC -shared -lusb-1.0
CFLAGS ?= -fPIC -O2 -Wall -Wextra -Wno-unused-parameter

ifeq ($(CROSSCOMPILE),)
ifeq ($(shell uname),Darwin)
LDFLAGS += -undefined dynamic_lookup
endif
endif

# BUILD_DIR := $(PWD)/_build

PRIV_DIR := $(MIX_APP_PATH)/priv
LIBUSB_NIF := $(PRIV_DIR)/libusb_nif.so

.PHONY: all clean dir-clean

all: $(PRIV_DIR) $(LIBUSB_NIF)

$(PRIV_DIR):
	mkdir -p $(PRIV_DIR)

$(LIBUSB_NIF): c_src/libusb_nif.c
	$(CC) $(ERL_CFLAGS) $(CFLAGS) $(ERL_LDFLAGS) $(LDFLAGS) \
	-o $@ $<

clean:
	$(RM) $(LIBUSB_NIF)
	$(RM) c_src/*.o

dir-clean: clean libusb-clean
	$(RM) $(LIBUSB_NOF)
