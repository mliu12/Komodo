ifneq ($(KERNELRELEASE),)

ccflags-y := -I$(M)/../include
obj-m := komodo.o
komodo-y := driver.o smc.o smcapi.o pgalloc.o encloader.o enc.elfbin

else

-include ../config.mk
export KERNELDIR ?= /lib/modules/$(shell uname -r)/build
export ARCH ?= arm
export CROSS_COMPILE ?= arm-linux-gnueabihf-
PWD := $(shell pwd)

default:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules

endif
