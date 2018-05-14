#include <erl_nif.h>
#include <libusb-1.0/libusb.h>
#include <stdio.h>
#include <string.h>

#define MAX_BUF_LENGTH 255

static int map_put(ErlNifEnv *env, ERL_NIF_TERM map_in, ERL_NIF_TERM* map_out, ERL_NIF_TERM key, ERL_NIF_TERM value)
{
    return enif_make_map_put(env, map_in, key, value, map_out);
}

static ERL_NIF_TERM build_dev_list(ErlNifEnv *env, libusb_device *dev) {
    struct libusb_device_descriptor desc;
    libusb_device_handle *handle = NULL;

    char string[MAX_BUF_LENGTH];

    int ret;
    uint8_t i;

    ERL_NIF_TERM dev_map = enif_make_new_map(env);
    ErlNifBinary bin;

    ret = libusb_get_device_descriptor(dev, &desc);
    if (ret < 0) {
        enif_fprintf(stderr, "failed to get device descriptor");
    }

    ret = libusb_open(dev, &handle);
    if (ret == LIBUSB_SUCCESS) {

        if (desc.iManufacturer) {
            ret = libusb_get_string_descriptor_ascii(handle, desc.iManufacturer, (unsigned char *)string, sizeof(string));
            if (ret > 0) {
                enif_alloc_binary(strlen(string), &bin);
                memcpy(bin.data, string, bin.size);
                map_put(env, dev_map, &dev_map, enif_make_atom(env, "iManufacturer"), enif_make_binary(env, &bin));
            }
        }

        if (desc.iProduct) {
            ret = libusb_get_string_descriptor_ascii(handle, desc.iProduct, (unsigned char *)string, sizeof(string));
            if (ret > 0) {
                enif_alloc_binary(strlen(string), &bin);
                memcpy(bin.data, string, bin.size);
                map_put(env, dev_map, &dev_map, enif_make_atom(env, "iProduct"), enif_make_binary(env, &bin));
            }
        }

    }

    map_put(env, dev_map, &dev_map, enif_make_atom(env, "bus_number"), enif_make_int(env, libusb_get_bus_number(dev)));
    map_put(env, dev_map, &dev_map, enif_make_atom(env, "device_address"), enif_make_int(env, libusb_get_device_address(dev)));
    map_put(env, dev_map, &dev_map, enif_make_atom(env, "idProduct"), enif_make_int(env, desc.idProduct));
    map_put(env, dev_map, &dev_map, enif_make_atom(env, "idVendor"), enif_make_int(env, desc.idVendor));

    if (handle) {
        if (desc.iSerialNumber) {
            ret = libusb_get_string_descriptor_ascii(handle, desc.iSerialNumber, (unsigned char *)string, sizeof(string));
            if (ret > 0) {
                enif_alloc_binary(strlen(string), &bin);
                memcpy(bin.data, string, bin.size);
                map_put(env, dev_map, &dev_map, enif_make_atom(env, "iSerialNumber"), enif_make_binary(env, &bin));
            }
        }
    }

    if (handle)
        libusb_close(handle);

    enif_release_binary(&bin);
    return dev_map;
}


static ERL_NIF_TERM list_devices(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    libusb_device **devs;
    ssize_t cnt;
    int r, i;

    r = libusb_init(NULL);
    if (r < 0)
        return enif_make_badarg(env);

    cnt = libusb_get_device_list(NULL, &devs);
    if (cnt < 0) {
        return enif_make_badarg(env);
    }

    ERL_NIF_TERM ret_arr[cnt];

    enif_fprintf(stderr, "Starting list.\r\n");
    for(i = 0; devs[i]; ++i) {
        ret_arr[i] = build_dev_list(env, devs[i]);
    }

    libusb_free_device_list(devs, 1);

    libusb_exit(NULL);

    enif_fprintf(stderr, "Done.\r\n");

    return enif_make_list_from_array(env, ret_arr, cnt);
}

static ErlNifFunc nif_funcs[] = {
    {"list_devices", 0, list_devices}
};

ERL_NIF_INIT(Elixir.LibUsb, nif_funcs, NULL, NULL, NULL, NULL)
