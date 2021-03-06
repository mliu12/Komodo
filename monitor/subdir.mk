ifeq ($(INSECUREMONITOR), 1)
MONITOR_OBJS := $(dir)/entry.o $(dir)/monitor.o
MONITOR_INPUTS := $(MONITOR_OBJS) pdclib/pdclib.a
else
MONITOR_OBJS :=
MONITOR_INPUTS := verified/main.o
endif

MONITOR_LINKER_SCRIPT := $(dir)/monitor.lds

$(dir)/monitor.elf: $(MONITOR_INPUTS) $(MONITOR_LINKER_SCRIPT)
	$(LD) $(LDFLAGS_ALL) -T $(MONITOR_LINKER_SCRIPT) -o $@ $(MONITOR_INPUTS)

-include $(MONITOR_OBJS:.o=.d)

CLEAN := $(CLEAN) $(dir)/monitor.elf $(MONITOR_OBJS) $(MONITOR_OBJS:.o=.d)
