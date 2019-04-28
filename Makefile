ifeq ($(ERL_EI_INCLUDE_DIR),)
$(warn ERL_EI_INCLUDE_DIR not set. Invoke via mix)
endif

$(warn $(ERL_EI_INCLUDE_DIR))

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)

#LIBUSB_VERSION := 1.0.22
#LIBUSB_SRC_DIR := $(PWD)/c_src/libusb-$(LIBUSB_VERSION)
#LIBUSB_BUILD_DIR := $(BUILD_DIR)/libusb
#LIBUSB_INCLUDE_DIR := /usr/include/libusb-1.0
# LIBUSB_INCLUDE_DIR := /usr/include/libusb
# LIBUSB_LIBDIR := $(LIBUSB_BUILD_DIR)/lib
#LIBUSB_LIB := $(LIBUSB_LIBDIR)/libusb-1.0.so

LIBUSB_INCLUDE_DIR := -I/usr/include/libusb-1.0
LIBUSB_LIBDIR := -L/usr/lib/x86_64-linux-gnu

BUILD_DIR := $(PWD)/_build

PRIV_DIR := priv
LIBUSB_NIF := $(PRIV_DIR)/libusb_nif.so

#LIBUSB_CFLAGS := -I$(LIBUSB_INCLUDE_DIR)
#LIBUSB_LDFLAGS := -L$(LIBUSB_LIBDIR) -lusb-1.0
LIBUSB_CFLAGS := 
LIBUSB_LDFLAGS := -lusb-1.0

LIBUSB_NIF_SRC := c_src/libusb_nif.c

NIF_CFLAGS := -O2
NIF_LDFLAGS := -fPIC -shared -pedantic

.PHONY: all clean dir-clean

all: $(PRIV_DIR) $(LIBUSB_NIF)

$(PRIV_DIR):
	mkdir -p $(PRIV_DIR)

$(LIBUSB_NIF): $(LIBUSB_LIB) $(LIBUSB_NIF_SRC)
	$(CC) -o $@ $(LIBUSB_NIF_SRC) \
	$(LIBUSB_CFLAGS) $(ERL_CFLAGS) $(NIF_CFLAGS) \
	$(LIBUSB_LDFLAGS) $(ERL_LDFLAGS) $(NIF_LDFLAGS)

clean:
	$(RM) $(LIBUSB_NIF)
	$(RM) c_src/*.o

dir-clean: clean libusb-clean
	$(RM) -rf priv
	$(RM) $(LIBUSB_SRC_DIR)/config.status
	$(RM) -rf $(LIBUSB_BUILD_DIR)
