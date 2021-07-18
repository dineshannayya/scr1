//////////////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText: Syntacore LLC © 2016-2021
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0
// SPDX-FileContributor: Syntacore LLC
// //////////////////////////////////////////////////////////////////////////
/// @file       <scr1_imem_router.sv>
/// @brief      Instruction memory router
///
`include "scr1_memif.svh"
`include "scr1_arch_description.svh"

module scr1_imem_router
#(
    parameter SCR1_ADDR_MASK    = `SCR1_IMEM_AWIDTH'hFFFF0000,
    parameter SCR1_ADDR_PATTERN = `SCR1_IMEM_AWIDTH'h00010000
)
(
    // Control signals
    input   logic                           rst_n,
    input   logic                           clk,

    // Core interface
    output  logic                           imem_req_ack,
    input   logic                           imem_req,
    input   logic                           imem_cmd,
    input   logic [`SCR1_IMEM_AWIDTH-1:0]   imem_addr,
    output  logic [`SCR1_IMEM_DWIDTH-1:0]   imem_rdata,
    output  logic [1:0]                     imem_resp,

    // PORT0 interface
    input   logic                           port0_req_ack,
    output  logic                           port0_req,
    output  logic                           port0_cmd,
    output  logic [`SCR1_IMEM_AWIDTH-1:0]   port0_addr,
    input   logic [`SCR1_IMEM_DWIDTH-1:0]   port0_rdata,
    input   logic [1:0]                     port0_resp,

    // PORT1 interface
    input   logic                           port1_req_ack,
    output  logic                           port1_req,
    output  logic                           port1_cmd,
    output  logic [`SCR1_IMEM_AWIDTH-1:0]   port1_addr,
    input   logic [`SCR1_IMEM_DWIDTH-1:0]   port1_rdata,
    input   logic [1:0]                     port1_resp
);

//-------------------------------------------------------------------------------
// Local types declaration
//-------------------------------------------------------------------------------
typedef enum logic {
    SCR1_FSM_ADDR,
    SCR1_FSM_DATA
} type_scr1_fsm_e;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
type_scr1_fsm_e                 fsm;
logic                           port_sel;
logic                           port_sel_r;
logic [`SCR1_IMEM_DWIDTH-1:0]   sel_rdata;
logic [1:0]                     sel_resp;
logic                           sel_req_ack;

//-------------------------------------------------------------------------------
// FSM
//-------------------------------------------------------------------------------
assign port_sel = ((imem_addr & SCR1_ADDR_MASK) == SCR1_ADDR_PATTERN);

always_ff @(negedge rst_n, posedge clk) begin
    if (~rst_n) begin
        fsm        <= SCR1_FSM_ADDR;
        port_sel_r <= 1'b0;
    end else begin
        case (fsm)
            SCR1_FSM_ADDR : begin
                if (imem_req & sel_req_ack) begin
                    fsm <= SCR1_FSM_DATA;
                    port_sel_r <= port_sel;
                end
            end
            SCR1_FSM_DATA : begin
                case (sel_resp)
                    SCR1_MEM_RESP_RDY_OK : begin
                        if (imem_req & sel_req_ack) begin
                            fsm <= SCR1_FSM_DATA;
                            port_sel_r <= port_sel;
                        end else begin
                            fsm <= SCR1_FSM_ADDR;
                        end
                    end
                    SCR1_MEM_RESP_RDY_ER : begin
                        fsm <= SCR1_FSM_ADDR;
                    end
                    default : begin
                    end
                endcase
            end
            default : begin
            end
        endcase
    end
end

always_comb begin
    if ((fsm == SCR1_FSM_ADDR) | ((fsm == SCR1_FSM_DATA) & (sel_resp == SCR1_MEM_RESP_RDY_OK))) begin
        sel_req_ack = (port_sel) ? port1_req_ack : port0_req_ack;
    end else begin
        sel_req_ack = 1'b0;
    end
end

assign sel_rdata = (port_sel_r) ? port1_rdata : port0_rdata;
assign sel_resp  = (port_sel_r) ? port1_resp  : port0_resp;

//-------------------------------------------------------------------------------
// Interface to core
//-------------------------------------------------------------------------------
assign imem_req_ack = sel_req_ack;
assign imem_rdata   = sel_rdata;
assign imem_resp    = sel_resp;

//-------------------------------------------------------------------------------
// Interface to PORT0
//-------------------------------------------------------------------------------
always_comb begin
    port0_req = 1'b0;
    case (fsm)
        SCR1_FSM_ADDR : begin
            port0_req = imem_req & ~port_sel;
        end
        SCR1_FSM_DATA : begin
            if (sel_resp == SCR1_MEM_RESP_RDY_OK) begin
                port0_req = imem_req & ~port_sel;
            end
        end
        default : begin
        end
    endcase
end

`ifdef SCR1_XPROP_EN
assign port0_cmd   = (~port_sel) ? imem_cmd  : SCR1_MEM_CMD_ERROR;
assign port0_addr  = (~port_sel) ? imem_addr : 'x;
`else // SCR1_XPROP_EN
assign port0_cmd   = imem_cmd ;
assign port0_addr  = imem_addr;
`endif // SCR1_XPROP_EN

//-------------------------------------------------------------------------------
// Interface to PORT1
//-------------------------------------------------------------------------------
always_comb begin
    port1_req = 1'b0;
    case (fsm)
        SCR1_FSM_ADDR : begin
            port1_req = imem_req & port_sel;
        end
        SCR1_FSM_DATA : begin
            if (sel_resp == SCR1_MEM_RESP_RDY_OK) begin
                port1_req = imem_req & port_sel;
            end
        end
        default : begin
        end
    endcase
end

`ifdef SCR1_XPROP_EN
assign port1_cmd   = (port_sel) ? imem_cmd  : SCR1_MEM_CMD_ERROR;
assign port1_addr  = (port_sel) ? imem_addr : 'x;
`else // SCR1_XPROP_EN
assign port1_cmd   = imem_cmd ;
assign port1_addr  = imem_addr;
`endif // SCR1_XPROP_EN

`ifdef SCR1_TRGT_SIMULATION
//-------------------------------------------------------------------------------
// Assertion
//-------------------------------------------------------------------------------

SCR1_SVA_IMEM_RT_XCHECK : assert property (
    @(negedge clk) disable iff (~rst_n)
    imem_req |-> !$isunknown({port_sel, imem_cmd})
    ) else $error("IMEM router Error: unknown values");

`endif // SCR1_TRGT_SIMULATION

endmodule : scr1_imem_router
