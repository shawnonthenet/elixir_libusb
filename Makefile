ifeq ($(ERL_EI_INCLUDE_DIR),)
$(warn ERL_EI_INCLUDE_DIR not set. Invoke via mix)
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)

BUILD_DIR := $(PWD)/_build
LIBUSB_SRC_DIR := $(PWD)/c_src/libusb-1.0.22
LIBUSB_BUILD_DIR := $(BUILD_DIR)/libusb
LIBUSB_INCLUDE_DIR := $(LIBUSB_BUILD_DIR)/include/
LIBUSB_LIBDIR := $(LIBUSB_BUILD_DIR)/lib/
LIBUSB_LIB := $(LIBUSB_LIBDIR)/libusb-1.0.so

PRIV_DIR := priv
LIBUSB_NIF := $(PRIV_DIR)/libusb_nif.so
LIBUSB_CFLAGS := -I$(LIBUSB_INCLUDE_DIR)
LIBUSB_LDFLAGS := -L$(LIBUSB_LIBDIR) -lusb-1.0
LIBUSB_NIF_SRC := c_src/libusb_nif.c

NIF_CFLAGS := -O2
NIF_LDFLAGS := -fPIC -shared -pedantic

.PHONY: all clean libusb-clean dir-clean

all: $(PRIV_DIR) $(LIBUSB_NIF)

$(PRIV_DIR):
	mkdir -p $(PRIV_DIR)

$(LIBUSB_BUILD_DIR):
	mkdir -p $(LIBUSB_BUILD_DIR)

$(LIBUSB_SRC_DIR)/config.status: $(LIBUSB_BUILD_DIR)
	cd $(LIBUSB_SRC_DIR) && ./configure --prefix=$(LIBUSB_BUILD_DIR)

$(LIBUSB_LIB): $(LIBUSB_SRC_DIR)/config.status
	cd $(LIBUSB_SRC_DIR) && make install

$(LIBUSB_NIF): $(LIBUSB_LIB) $(LIBUSB_NIF_SRC)
	$(CC) -o $@ $(LIBUSB_NIF_SRC) \
	$(LIBUSB_CFLAGS) $(ERL_CFLAGS) $(NIF_CFLAGS) \
	$(LIBUSB_LDFLAGS) $(ERL_LDFLAGS) $(NIF_LDFLAGS)

clean:
	$(RM) $(LIBUSB_NIF)
	$(RM) c_src/*.o

libusb-clean:
	cd $(LIBUSB_SRC_DIR) && make clean

dir-clean: clean libusb-clean
	$(RM) -rf priv
	$(RM) $(LIBUSB_SRC_DIR)/config.status
	$(RM) -rf $(LIBUSB_BUILD_DIR)
