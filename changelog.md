
18-July 2021 - Dinesh.A - Forked from https://github.com/syntacore/scr1
18-July 2021 - Dinesh.A - 1. Update the rtl changes done for meet the openlane tool set
                          like simulation(iverilog) + yosys (synthesis)
                          2. wishbone interface added to support yifive project 
                          3. Made core clock and wishbone clock made async to avoid
                             core_clock deciding the system clock
                          following files are updated
                         	modified:   src/core/pipeline/scr1_ipic.sv
                         	modified:   src/core/pipeline/scr1_pipe_csr.sv
                         	modified:   src/core/pipeline/scr1_pipe_exu.sv
                         	modified:   src/core/pipeline/scr1_pipe_hdu.sv
                         	modified:   src/core/pipeline/scr1_pipe_ialu.sv
                         	modified:   src/core/pipeline/scr1_pipe_idu.sv
                         	modified:   src/core/pipeline/scr1_pipe_ifu.sv
                         	modified:   src/core/pipeline/scr1_pipe_lsu.sv
                         	modified:   src/core/pipeline/scr1_pipe_mprf.sv
                         	modified:   src/core/pipeline/scr1_pipe_tdu.sv
                         	modified:   src/core/pipeline/scr1_pipe_top.sv
                         	modified:   src/core/pipeline/scr1_tracelog.sv
                         	modified:   src/core/primitives/scr1_cg.sv
                         	modified:   src/core/primitives/scr1_reset_cells.sv
                         	modified:   src/core/scr1_clk_ctrl.sv
                         	modified:   src/core/scr1_core_top.sv
                         	modified:   src/core/scr1_dm.sv
                         	modified:   src/core/scr1_dmi.sv
                         	modified:   src/core/scr1_scu.sv
                         	modified:   src/core/scr1_tapc.sv
                         	modified:   src/core/scr1_tapc_shift_reg.sv
                         	modified:   src/core/scr1_tapc_synchronizer.sv
                         	modified:   src/includes/scr1_ahb.svh
                         	modified:   src/includes/scr1_arch_description.svh
                         	modified:   src/includes/scr1_arch_types.svh
                         	modified:   src/includes/scr1_csr.svh
                         	modified:   src/includes/scr1_dm.svh
                         	modified:   src/includes/scr1_hdu.svh
                         	modified:   src/includes/scr1_ipic.svh
                         	modified:   src/includes/scr1_memif.svh
                         	modified:   src/includes/scr1_riscv_isa_decoding.svh
                         	modified:   src/includes/scr1_scu.svh
                         	modified:   src/includes/scr1_search_ms1.svh
                         	modified:   src/includes/scr1_tapc.svh
                         	modified:   src/includes/scr1_tdu.svh
                         	modified:   src/tb/scr1_memory_tb_ahb.sv
                         	modified:   src/tb/scr1_memory_tb_axi.sv
                         	modified:   src/tb/scr1_top_tb_ahb.sv
                         	modified:   src/tb/scr1_top_tb_axi.sv
                         	modified:   src/tb/scr1_top_tb_runtests.sv
                         	modified:   src/top/scr1_dmem_ahb.sv
                         	modified:   src/top/scr1_dmem_router.sv
                         	modified:   src/top/scr1_dp_memory.sv
                         	modified:   src/top/scr1_imem_ahb.sv
                         	modified:   src/top/scr1_imem_router.sv
                         	modified:   src/top/scr1_mem_axi.sv
                         	modified:   src/top/scr1_tcm.sv
                         	modified:   src/top/scr1_timer.sv
                         	modified:   src/top/scr1_top_ahb.sv
                         	modified:   src/top/scr1_top_axi.sv


19-July 2021 - Dinesh.A - 1. Modfy the multi logic with 8 staged logic due to timing reason
        new file:   src/core/pipeline/scr1_pipe_mul.sv
        modified:   src/core.files
	modified:   src/core/pipeline/scr1_pipe_ialu.sv
	modified:   src/includes/scr1_arch_description.svh
	modified:   src/tb/scr1_top_tb_runtests.sv

20-July 2021 - Dinesh.A  Modified the divider logic added 16 staged logic is added due to timing reason
	modified:   src/core.files
	modified:   src/core/pipeline/scr1_pipe_ialu.sv
	modified:   src/core/pipeline/scr1_pipe_mul.sv
        modified:   src/core/pipeline/scr1_pipe_div.sv
26-July 2021 - Dinesh.A, Modified the 64 Bit additional logic for 2's complement is broken into 32bit addition for timing reason
	modified:   src/core/pipeline/scr1_pipe_mul.sv
	modified:   src/top/scr1_timer.sv
16-Aug 2021 - Dinesh A, iverilog compile support added + wishbone interface testing update done
	modified:   Makefile
	modified:   sim/Makefile
	new file:   sim/iverilog_vpi/system.c
	modified:   sim/tests/test/test.c
	modified:   src/core/pipeline/scr1_pipe_ialu.sv
	modified:   src/tb/scr1_memory_tb_wb.sv
	modified:   src/tb/scr1_top_tb_runtests.sv
	modified:   src/tb/scr1_top_tb_wb.sv
23-Aug 2021 - Dinesh A, timer_irq connectivity bug fix
	modified:   src/top/scr1_intf.sv
	modified:   src/top/scr1_top_wb.sv


     

