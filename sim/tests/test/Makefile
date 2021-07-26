src_dir := $(dir $(lastword $(MAKEFILE_LIST)))

c_src := test.c coremark.h

include $(inc_dir)/common.mk

default: log_requested_tgt $(bld_dir)/test.elf $(bld_dir)/test.hex $(bld_dir)/test.dump

log_requested_tgt:
	echo test.hex>> $(bld_dir)/test_info

clean:
	$(RM) $(c_objs) $(asm_objs) $(bld_dir)/test.elf $(bld_dir)/test.hex $(bld_dir)/test.dump
