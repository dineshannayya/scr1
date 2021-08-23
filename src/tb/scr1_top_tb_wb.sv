/// Copyright by Syntacore LLC © 2016-2020. See LICENSE for details
/// @file       <scr1_top_tb_ahb.sv>
/// @brief      SCR1 top testbench Wishbone
///

`include "scr1_arch_description.svh"
`include "scr1_ahb.svh"
`ifdef SCR1_IPIC_EN
`include "scr1_ipic.svh"
`endif // SCR1_IPIC_EN

module scr1_top_tb_wb (
`ifdef VERILATOR
    input logic clk
`endif // VERILATOR
);

//-------------------------------------------------------------------------------
// Local parameters
//-------------------------------------------------------------------------------
localparam                          SCR1_MEM_SIZE       = 1024*1024;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
logic                                   rst_n;
`ifndef VERILATOR
logic                                   clk         = 1'b0;
`endif // VERILATOR
logic                                   rtc_clk     = 1'b0;
`ifdef SCR1_IPIC_EN
logic [SCR1_IRQ_LINES_NUM-1:0]          irq_lines;
`else // SCR1_IPIC_EN
logic                                   ext_irq;
`endif // SCR1_IPIC_EN
logic                                   soft_irq;
logic [31:0]                            fuse_mhartid;
integer                                 imem_req_ack_stall;
integer                                 dmem_req_ack_stall;

logic                                   test_mode   = 1'b0;
`ifdef SCR1_DBG_EN
logic                                   trst_n;
logic                                   tck;
logic                                   tms;
logic                                   tdi;
logic                                   tdo;
logic                                   tdo_en;
`endif // SCR1_DBG_EN
logic                                   wb_rst_n;       // Wish bone reset
logic                                   wb_clk = 1'b0;  // wish bone clock
// Instruction Memory Interface
logic                                   wbd_imem_stb_o; // strobe/request
logic   [SCR1_WB_WIDTH-1:0]             wbd_imem_adr_o; // address
logic                                   wbd_imem_we_o;  // write
logic   [SCR1_WB_WIDTH-1:0]             wbd_imem_dat_o; // data output
logic   [3:0]                           wbd_imem_sel_o; // byte enable
logic   [SCR1_WB_WIDTH-1:0]             wbd_imem_dat_i; // data input
logic                                   wbd_imem_ack_i; // acknowlegement
logic                                   wbd_imem_err_i;  // error

// Data Memory Interface
logic                                   wbd_dmem_stb_o; // strobe/request
logic   [SCR1_WB_WIDTH-1:0]             wbd_dmem_adr_o; // address
logic                                   wbd_dmem_we_o;  // write
logic   [SCR1_WB_WIDTH-1:0]             wbd_dmem_dat_o; // data output
logic   [3:0]                           wbd_dmem_sel_o; // byte enable
logic   [SCR1_WB_WIDTH-1:0]             wbd_dmem_dat_i; // data input
logic                                   wbd_dmem_ack_i; // acknowlegement
logic                                   wbd_dmem_err_i; // error

int unsigned                            f_results;
int unsigned                            f_info;

string                                  s_results;
string                                  s_info;
`ifdef SIGNATURE_OUT
string                                  s_testname;
bit                                     b_single_run_flag;
`endif  //  SIGNATURE_OUT
`ifdef VERILATOR
logic [255:0]                           test_file;
`else // VERILATOR
string                                  test_file;
`endif // VERILATOR

bit                                     test_running;
int unsigned                            tests_passed;
int unsigned                            tests_total;

bit [1:0]                               rst_cnt;
bit                                     rst_init;
logic [15:0] riscv_dmem_req_cnt; // cnt dmem req


`ifdef VERILATOR
function bit is_compliance (logic [255:0] testname);
    bit res;
    logic [79:0] pattern;
begin
    pattern = 80'h636f6d706c69616e6365; // compliance
    res = 0;
    for (int i = 0; i<= 176; i++) begin
        if(testname[i+:80] == pattern) begin
            return ~res;
        end
    end
    `ifdef SIGNATURE_OUT
        return ~res;
    `else
        return res;
    `endif
end
endfunction : is_compliance

function logic [255:0] get_filename (logic [255:0] testname);
logic [255:0] res;
int i, j;
begin
    testname[7:0] = 8'h66;
    testname[15:8] = 8'h6C;
    testname[23:16] = 8'h65;

    for (i = 0; i <= 248; i += 8) begin
        if (testname[i+:8] == 0) begin
            break;
        end
    end
    i -= 8;
    for (j = 255; i >= 0;i -= 8) begin
        res[j-:8] = testname[i+:8];
        j -= 8;
    end
    for (; j >= 0;j -= 8) begin
        res[j-:8] = 0;
    end

    return res;
end
endfunction : get_filename

function logic [255:0] get_ref_filename (logic [255:0] testname);
logic [255:0] res;
int i, j;
logic [79:0] pattern;
begin
    pattern = 80'h636f6d706c69616e6365; // compliance

    for(int i = 0; i <= 176; i++) begin
        if(testname[i+:80] == pattern) begin
            testname[(i-8)+:88] = 0;
            break;
        end
    end

    for(i = 32; i <= 248; i += 8) begin
        if(testname[i+:8] == 0) break;
    end
    i -= 8;
    for(j = 255; i > 24; i -= 8) begin
        res[j-:8] = testname[i+:8];
        j -= 8;
    end
    for(; j >=0;j -= 8) begin
        res[j-:8] = 0;
    end

    return res;
end
endfunction : get_ref_filename

function logic [2047:0] remove_trailing_whitespaces (logic [2047:0] str);
int i;
begin
    for (i = 0; i <= 2040; i += 8) begin
        if (str[i+:8] != 8'h20) begin
            break;
        end
    end
    str = str >> i;
    return str;
end
endfunction: remove_trailing_whitespaces

`else // VERILATOR
function bit is_compliance (string testname);
begin
    return (testname.substr(0, 9) == "compliance");
end
endfunction : is_compliance

function string get_filename (string testname);
int length;
begin
    length = testname.len();
    testname[length-1] = "f";
    testname[length-2] = "l";
    testname[length-3] = "e";

    return testname;
end
endfunction : get_filename

function string get_ref_filename (string testname);
begin
    return testname.substr(11, testname.len() - 5);
end
endfunction : get_ref_filename

`endif // VERILATOR

`ifndef VERILATOR
always #5   clk     = ~clk;         // 100 MHz
always #5   wb_clk  = ~wb_clk;      // 100 MHz
always #500 rtc_clk = ~rtc_clk;     // 1 MHz
`endif // VERILATOR

// Reset logic
assign rst_n = &rst_cnt;

always_ff @(posedge clk) begin
     if (rst_init)       begin
	rst_cnt <= '0;
        riscv_dmem_req_cnt <= 0;
    end
    else if (~&rst_cnt) rst_cnt <= rst_cnt + 1'b1;
end


`ifdef SCR1_DBG_EN
initial begin
    trst_n  = 1'b0;
    tck     = 1'b0;
    tdi     = 1'b0;
    #900ns trst_n   = 1'b1;
    #500ns tms      = 1'b1;
    #800ns tms      = 1'b0;
    #500ns trst_n   = 1'b0;
    #100ns tms      = 1'b1;
end
`endif // SCR1_DBG_EN




//-------------------------------------------------------------------------------
// Run tests
//-------------------------------------------------------------------------------

`include "scr1_top_tb_runtests.sv"
//-------------------------------------------------------------------------------
// Core instance
//-------------------------------------------------------------------------------
scr1_top_wb i_top (
    // Reset
    .pwrup_rst_n            (rst_n                  ),
    .rst_n                  (rst_n                  ),
    .cpu_rst_n              (rst_n                  ),
`ifdef SCR1_DBG_EN
    .sys_rst_n_o            (                       ),
    .sys_rdc_qlfy_o         (                       ),
`endif // SCR1_DBG_EN

    // Clock
    .core_clk               (clk                    ),
    .rtc_clk                (rtc_clk                ),
    .riscv_debug            (                       ),

    // Fuses
    .fuse_mhartid           (fuse_mhartid           ),
`ifdef SCR1_DBG_EN
    .fuse_idcode            (`SCR1_TAP_IDCODE       ),
`endif // SCR1_DBG_EN

    // IRQ
`ifdef SCR1_IPIC_EN
    .irq_lines              (irq_lines              ),
`else // SCR1_IPIC_EN
    .ext_irq                (ext_irq                ),
`endif // SCR1_IPIC_EN
    .soft_irq               (soft_irq               ),

    // DFT
    //.test_mode              (1'b0                   ),
    //.test_rst_n             (1'b1                   ),

`ifdef SCR1_DBG_EN
    // JTAG
    .trst_n                 (trst_n                 ),
    .tck                    (tck                    ),
    .tms                    (tms                    ),
    .tdi                    (tdi                    ),
    .tdo                    (tdo                    ),
    .tdo_en                 (tdo_en                 ),
`endif // SCR1_DBG_EN

    .wb_rst_n               (rst_n                  ),
    .wb_clk                 (clk                    ),

    .wbd_imem_stb_o         (wbd_imem_stb_o         ),
    .wbd_imem_adr_o         (wbd_imem_adr_o         ),
    .wbd_imem_we_o          (wbd_imem_we_o          ),
    .wbd_imem_dat_o         (wbd_imem_dat_o         ),
    .wbd_imem_sel_o         (wbd_imem_sel_o         ),
    .wbd_imem_dat_i         (wbd_imem_dat_i         ),
    .wbd_imem_ack_i         (wbd_imem_ack_i         ),
    .wbd_imem_err_i         (wbd_imem_err_i         ),

    .wbd_dmem_stb_o         (wbd_dmem_stb_o         ),
    .wbd_dmem_adr_o         (wbd_dmem_adr_o         ),
    .wbd_dmem_we_o          (wbd_dmem_we_o          ),
    .wbd_dmem_dat_o         (wbd_dmem_dat_o         ),
    .wbd_dmem_sel_o         (wbd_dmem_sel_o         ),
    .wbd_dmem_dat_i         (wbd_dmem_dat_i         ),
    .wbd_dmem_ack_i         (wbd_dmem_ack_i         ),
    .wbd_dmem_err_i         (wbd_dmem_err_i         )

);

//-------------------------------------------------------------------------------
// Memory instance
//-------------------------------------------------------------------------------
scr1_memory_tb_wb #(
    .SCR1_MEM_POWER_SIZE    ($clog2(SCR1_MEM_SIZE))
) i_memory_tb (
    // Control
    .rst_n                  (rst_n                  ),
    .clk                    (clk                    ),
`ifdef SCR1_IPIC_EN
    .irq_lines              (irq_lines              ),
`else // SCR1_IPIC_EN
    .ext_irq                (ext_irq                ),
`endif // SCR1_IPIC_EN
    .soft_irq               (soft_irq               ),
    .imem_req_ack_stall_in  (imem_req_ack_stall     ),
    .dmem_req_ack_stall_in  (dmem_req_ack_stall     ),

    .wbd_imem_stb_i         (wbd_imem_stb_o         ),
    .wbd_imem_adr_i         (wbd_imem_adr_o         ),
    .wbd_imem_we_i          (wbd_imem_we_o          ),
    .wbd_imem_dat_i         (wbd_imem_dat_o         ),
    .wbd_imem_sel_i         (wbd_imem_sel_o         ),
    .wbd_imem_dat_o         (wbd_imem_dat_i         ),
    .wbd_imem_ack_o         (wbd_imem_ack_i         ),
    .wbd_imem_err_o         (wbd_imem_err_i         ),

    .wbd_dmem_stb_i         (wbd_dmem_stb_o         ),
    .wbd_dmem_adr_i         (wbd_dmem_adr_o         ),
    .wbd_dmem_we_i          (wbd_dmem_we_o          ),
    .wbd_dmem_dat_i         (wbd_dmem_dat_o         ),
    .wbd_dmem_sel_i         (wbd_dmem_sel_o         ),
    .wbd_dmem_dat_o         (wbd_dmem_dat_i         ),
    .wbd_dmem_ack_o         (wbd_dmem_ack_i         ),
    .wbd_dmem_err_o         (wbd_dmem_err_i         )

);



always @(posedge wbd_dmem_stb_o)
begin
    riscv_dmem_req_cnt = riscv_dmem_req_cnt+1;
end

`ifdef WFDUMP
initial
begin
   $dumpfile("simx.vcd");
   $dumpvars(2,scr1_top_tb_wb);
   $dumpvars(4,scr1_top_tb_wb.i_top);
end
`endif



endmodule : scr1_top_tb_wb

