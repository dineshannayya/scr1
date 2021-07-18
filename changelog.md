
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

