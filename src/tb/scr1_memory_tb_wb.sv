/// Copyright by Syntacore LLC © 2016-2020. See LICENSE for details
/// @file       <scr1_memory_tb_ahb.sv>
/// @brief      AHB memory testbench
///

`include "scr1_arch_description.svh"
`include "scr1_wb.svh"
`include "scr1_ipic.svh"

module scr1_memory_tb_wb #(
`ifdef SCR1_TCM_EN
    parameter SCR1_MEM_POWER_SIZE  = 16
`else
    parameter SCR1_MEM_POWER_SIZE  = 23 // Memory sized increased for non TCM Mode
`endif
)
(
    // Control
    input   logic                                   rst_n,
    input   logic                                   clk,
`ifdef SCR1_IPIC_EN
    output  logic  [SCR1_IRQ_LINES_NUM-1:0]         irq_lines,
`else // SCR1_IPIC_EN
    output  logic                                   ext_irq,
`endif // SCR1_IPIC_EN
    output  logic                                   soft_irq,
    input   logic [SCR1_WB_WIDTH-1:0]               imem_req_ack_stall_in,
    input   logic [SCR1_WB_WIDTH-1:0]               dmem_req_ack_stall_in,

    // Instruction Memory Interface
    input  logic                                    wbd_imem_stb_i,
    input  logic [31:0]                             wbd_imem_adr_i         ,
    input  logic                                    wbd_imem_we_i          ,
    input  logic [31:0]                             wbd_imem_dat_i         ,
    input  logic [3:0]                              wbd_imem_sel_i         ,
    output logic [31:0]                             wbd_imem_dat_o         ,
    output logic                                    wbd_imem_ack_o         ,
    output logic                                    wbd_imem_err_o         ,

    // Memory Interface
    input  logic                                    wbd_dmem_stb_i         ,
    input  logic [31:0]                             wbd_dmem_adr_i         ,
    input  logic                                    wbd_dmem_we_i          ,
    input  logic [31:0]                             wbd_dmem_dat_i         ,
    input  logic [3:0]                              wbd_dmem_sel_i         ,
    output logic [31:0]                             wbd_dmem_dat_o         ,
    output logic                                    wbd_dmem_ack_o         ,
    output logic                                    wbd_dmem_err_o         

);

//-------------------------------------------------------------------------------
// Local Types
//-------------------------------------------------------------------------------
typedef enum logic {
    SCR1_STATE_IDLE = 1'b0,
    SCR1_STATE_DATA = 1'b1,
    SCR1_STATE_ERR  = 1'bx
} type_scr1_ahb_state_e;

//-------------------------------------------------------------------------------
// Memory definition
//-------------------------------------------------------------------------------
logic [7:0]                             memory [0:2**SCR1_MEM_POWER_SIZE-1];
`ifdef SCR1_IPIC_EN
logic [SCR1_IRQ_LINES_NUM-1:0]          irq_lines_reg;
`else // SCR1_IPIC_EN
logic                                   ext_irq_reg;
`endif // SCR1_IPIC_EN
logic                                   soft_irq_reg;
logic [7:0]                             mirage [0:2**SCR1_MEM_POWER_SIZE-1];
bit                                     mirage_en;
bit                                     mirage_rangeen;
bit [SCR1_WB_WIDTH-1:0]                mirage_adrlo = '1;
bit [SCR1_WB_WIDTH-1:0]                mirage_adrhi = '1;

`ifdef VERILATOR
logic [255:0]                           test_file;
`else // VERILATOR
string                                  test_file;
`endif // VERILATOR
bit                                     test_file_init;


assign wbd_imem_err_o = 0;
assign wbd_dmem_err_o = 0;

//-------------------------------------------------------------------------------
// Local functions
//-------------------------------------------------------------------------------
function logic [SCR1_WB_WIDTH-1:0] scr1_read_mem(
    logic   [SCR1_WB_WIDTH-1:0]    addr,
    logic   [3:0]                   r_be,
    logic   [3:0]                   w_hazard,
    logic   [SCR1_WB_WIDTH-1:0]    w_data,
    bit                             mirage_en
);
    logic [SCR1_WB_WIDTH-1:0]      tmp;
    logic [SCR1_MEM_POWER_SIZE-1:0] addr_mirage;
begin
    scr1_read_mem = 'x;

    if(~mirage_en) begin
        for (int unsigned i=0; i<4; ++i) begin
            tmp[(8*(i+1)-1)-:8] = (r_be[i])
                                        ? (w_hazard[i])
                                            ? w_data[(8*(i+1)-1)-:8]
                                            : memory[addr+i]
                                        : 'x;
        end
    end
    else begin
        addr_mirage = addr;
        for (int i = 0; i < 4; ++i) begin
            tmp[ (i*8)+:8 ] = (r_be[i])
                                        ? (w_hazard[i])
                                            ? w_data[(i*8)+:8]
                                            : mirage[addr_mirage+i]
                                        : 'x;
        end
    end
    //$display("MEMORY READ ADDRESS: %x Data: %x",addr,tmp);
    return tmp;
end
endfunction : scr1_read_mem

function void scr1_write_mem(
    logic   [SCR1_WB_WIDTH-1:0]    addr,
    logic   [3:0]                   w_be,
    logic   [SCR1_WB_WIDTH-1:0]    data,
    bit                             mirage_en
);
    logic [SCR1_MEM_POWER_SIZE-1:0] addr_mirage;
begin
    for (int unsigned i=0; i<4; ++i) begin
        if (w_be[i]) begin
            if(~mirage_en)
                memory[addr+i] <= data[(8*(i+1)-1)-:8];
            else begin
                addr_mirage = addr;
                mirage[addr_mirage+i] <= data[(8*(i+1)-1)-:8];
            end
        end
    end
end
endfunction : scr1_write_mem


//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
// IMEM access
type_scr1_ahb_state_e           imem_ahb_state;
logic   [SCR1_WB_WIDTH-1:0]    imem_ahb_addr;
logic   [SCR1_WB_WIDTH-1:0]    imem_req_ack_stall;
bit                             imem_req_ack_rnd;
logic                           imem_req_ack_i;
logic                           imem_req_ack_nc;
logic   [SCR1_WB_WIDTH-1:0]    imem_hrdata_l;
logic   [3:0]                   imem_wr_hazard;

// DMEM access
logic   [SCR1_WB_WIDTH-1:0]    dmem_req_ack_stall;
bit                             dmem_req_ack_rnd;
logic                           dmem_req_ack;
logic                           dmem_req_ack_nc;
type_scr1_ahb_state_e           dmem_state;
logic   [SCR1_WB_WIDTH-1:0]    dmem_ahb_addr;
logic   [2:0]                   dmem_ahb_size;
logic   [3:0]                   dmem_ahb_be;
logic   [SCR1_WB_WIDTH-1:0]    dmem_hrdata_l;
logic   [3:0]                   dmem_wr_hazard;

//-------------------------------------------------------------------------------
// Instruction memory ready
//-------------------------------------------------------------------------------
always_ff @(negedge rst_n, posedge clk) begin
    if (~rst_n) begin
        imem_req_ack_stall <= imem_req_ack_stall_in;
        imem_req_ack_rnd   <= 1'b0;
    end else begin
        if (imem_req_ack_stall == '0) begin
            imem_req_ack_rnd <= $random;
        end else begin
            imem_req_ack_stall <= {imem_req_ack_stall[0], imem_req_ack_stall[31:1]};
        end
    end
end

assign imem_req_ack_i = (imem_req_ack_stall == 32'd0) ?  imem_req_ack_rnd : imem_req_ack_stall[0];


//-------------------------------------------------------------------------------
// Address data generation
//-------------------------------------------------------------------------------
assign imem_wr_hazard = '0;

always_ff @(negedge rst_n, posedge clk) begin
    if (~rst_n) begin
        wbd_imem_dat_o    <= 'x;
	wbd_imem_ack_o   <= 1'b0;
    end else begin
        if (wbd_imem_stb_i && wbd_imem_we_i == 1'b0 && imem_req_ack_i && !wbd_imem_ack_o) begin // IMEM has only Read access
             if(mirage_rangeen & wbd_imem_adr_i>=mirage_adrlo & wbd_imem_adr_i<mirage_adrhi)
                 wbd_imem_dat_o <= scr1_read_mem({wbd_imem_adr_i[SCR1_WB_WIDTH-1:2], 2'b00}, wbd_imem_sel_i, imem_wr_hazard, wbd_dmem_dat_i, 1'b1);
             else
                 wbd_imem_dat_o <= scr1_read_mem({wbd_imem_adr_i[SCR1_WB_WIDTH-1:2], 2'b00}, wbd_imem_sel_i, imem_wr_hazard, wbd_dmem_dat_i, 1'b0);
	    wbd_imem_ack_o <= 1'b1;
        end else begin
                wbd_imem_dat_o  <= 'x;
	        wbd_imem_ack_o <= 1'b0;
        end
    end
end


//-------------------------------------------------------------------------------
// Data memory ready
//-------------------------------------------------------------------------------
always_ff @(negedge rst_n, posedge clk) begin
    if (~rst_n) begin
        dmem_req_ack_stall <= dmem_req_ack_stall_in;
        dmem_req_ack_rnd   <= 1'b0;
    end else begin
        if (dmem_req_ack_stall == 32'd0) begin
            dmem_req_ack_rnd <= $random;
        end else begin
            dmem_req_ack_stall <= {dmem_req_ack_stall[0], dmem_req_ack_stall[31:1]};
        end
    end
end

assign dmem_req_ack = (dmem_req_ack_stall == 32'd0) ?  dmem_req_ack_rnd : dmem_req_ack_stall[0];

//-------------------------------------------------------------------------------
// Data memory AHB FSM
//-------------------------------------------------------------------------------
always_ff @(negedge rst_n, posedge clk) begin
    if (~rst_n) begin
        dmem_state <= SCR1_STATE_IDLE;
    end else begin
        case (dmem_state)
            SCR1_STATE_IDLE : begin
                if (dmem_req_ack && wbd_dmem_stb_i && !wbd_dmem_ack_o) begin
                   dmem_state    <= SCR1_STATE_DATA;
                end
            end
            SCR1_STATE_DATA : begin
                  dmem_state    <= SCR1_STATE_IDLE;
            end
            default : begin
                dmem_state    <= SCR1_STATE_ERR;
            end
        endcase
    end
end

//-------------------------------------------------------------------------------
// Address command latch
//-------------------------------------------------------------------------------
assign dmem_wr_hazard = '0;
always_ff @(negedge rst_n, posedge clk) begin
    if (~rst_n) begin
        dmem_hrdata_l    <= '0;
    end else begin
        if (wbd_dmem_stb_i && ~wbd_dmem_we_i) begin
            case (wbd_dmem_adr_i)
                  // Reading Soft IRQ value
               SCR1_SIM_SOFT_IRQ_ADDR : begin
                  dmem_hrdata_l <= '0;
                  dmem_hrdata_l[0] <= soft_irq_reg;
               end
`ifdef SCR1_IPIC_EN
                  // Reading IRQ Lines values
               SCR1_SIM_EXT_IRQ_ADDR : begin
                  dmem_hrdata_l <= '0;
                  dmem_hrdata_l[SCR1_IRQ_LINES_NUM-1:0] <= irq_lines_reg;
               end
`else // SCR1_IPIC_EN
                 // Reading External IRQ value
              SCR1_SIM_EXT_IRQ_ADDR : begin
                 dmem_hrdata_l <= '0;
                 dmem_hrdata_l[0] <= ext_irq_reg;
              end
`endif // SCR1_IPIC_EN
             // Regular read operation
             default : begin
                if(mirage_rangeen & wbd_dmem_adr_i>=mirage_adrlo & wbd_dmem_adr_i<mirage_adrhi)
                   dmem_hrdata_l <= scr1_read_mem({wbd_dmem_adr_i[SCR1_WB_WIDTH-1:2], 2'b00}, wbd_dmem_sel_i, dmem_wr_hazard, wbd_dmem_dat_i, 1'b1);
                else
                   dmem_hrdata_l <= scr1_read_mem({wbd_dmem_adr_i[SCR1_WB_WIDTH-1:2], 2'b00}, wbd_dmem_sel_i, dmem_wr_hazard, wbd_dmem_dat_i, 1'b0);
             end
            endcase
	end
    end
end

//-------------------------------------------------------------------------------
// Data Memory response
//-------------------------------------------------------------------------------
always_comb begin
    wbd_dmem_ack_o = 1'b0;
    wbd_dmem_dat_o = 'x;
    case (dmem_state)
        SCR1_STATE_DATA : begin
            if (wbd_dmem_stb_i) begin
                wbd_dmem_ack_o = 1'b1;
                if (~wbd_dmem_we_i) begin
                    wbd_dmem_dat_o = dmem_hrdata_l;
                end
            end
        end
        default : begin
        end
    endcase
end

//-------------------------------------------------------------------------------
// Data Memory write
//-------------------------------------------------------------------------------
always @(negedge rst_n, posedge clk) begin
    if (~rst_n) begin
        soft_irq_reg   <= '0;
`ifdef SCR1_IPIC_EN
        irq_lines_reg  <= '0;
`else // SCR1_IPIC_EN
        ext_irq_reg    <= '0;
`endif // SCR1_IPIC_EN
        if (test_file_init) $readmemh(test_file, memory);
    end else begin
        if (wbd_dmem_stb_i && wbd_dmem_we_i && dmem_state == SCR1_STATE_DATA) begin
            case (wbd_dmem_adr_i)
                // Printing character in the simulation console
                SCR1_SIM_PRINT_ADDR : begin
                    $write("%c", wbd_dmem_dat_i[7:0]);
                end
                // Writing Soft IRQ value
                SCR1_SIM_SOFT_IRQ_ADDR : begin
                    soft_irq_reg <= wbd_dmem_dat_i[0];
                end
`ifdef SCR1_IPIC_EN
                // Writing IRQ Lines values
                SCR1_SIM_EXT_IRQ_ADDR : begin
                    irq_lines_reg <= wbd_dmem_dat_i[SCR1_IRQ_LINES_NUM-1:0];
                end
`else // SCR1_IPIC_EN
                // Writing External IRQ value
                SCR1_SIM_EXT_IRQ_ADDR : begin
                    ext_irq_reg <= wbd_dmem_dat_i[0];
                end
`endif // SCR1_IPIC_EN
                // Regular write operation
                default : begin
                    if(mirage_rangeen & wbd_dmem_adr_i>=mirage_adrlo & wbd_dmem_adr_i<mirage_adrhi)
                        scr1_write_mem({wbd_dmem_adr_i[SCR1_WB_WIDTH-1:2], 2'b00}, wbd_dmem_sel_i, wbd_dmem_dat_i, 1'b1);
                    else
                        scr1_write_mem({wbd_dmem_adr_i[SCR1_WB_WIDTH-1:2], 2'b00}, wbd_dmem_sel_i, wbd_dmem_dat_i, 1'b0);
                end
            endcase
        end
    end
end

`ifdef SCR1_IPIC_EN
assign irq_lines = irq_lines_reg;
`else // SCR1_IPIC_EN
assign ext_irq = ext_irq_reg;
`endif // SCR1_IPIC_EN
assign soft_irq = soft_irq_reg;

endmodule : scr1_memory_tb_wb
