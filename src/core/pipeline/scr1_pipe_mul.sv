//////////////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText: 2021, Dinesh Annayya
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
// SPDX-FileContributor: Dinesh Annayya <dinesha@opencores.org>
// //////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  32x32 Multiplier with 8 stage pipe line                     ////
////                                                              ////
////  This file is part of the yifive cores project               ////
////  https://github.com/dineshannayya/yifive_r0.git              ////
////  http://www.opencores.org/cores/yifive/                      ////
////                                                              ////
////  Description:                                                ////
////    32x32 Multiplier with 8 stage pipe line for timing reason ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
module scr1_pipe_mul (
	input   logic        clk, 
	input   logic        rstn, 
	input   logic        data_valid,   // input valid
	input   logic [32:0] Din1,         // first operand
	input   logic [32:0] Din2,         // second operand
	output  logic [31:0] des_hig,      // first result
	output  logic [31:0] des_low,      // second result
	output  logic        mul_rdy_o     // Multiply result ready
    );

parameter WAIT_CMD      = 2'b00; // Accept command and Do Signed to unsigned
parameter WAIT_COMP     = 2'b10; // Wait for COMPUTATION
parameter WAIT_DONE     = 2'b01; // Do Signed to Unsigned conversion 

// wires
logic [64:0] tmp_mul1, tmp_mul, shifted;
logic    data_valid_i;
logic [31:0] src1,src2; // Unsigned number

// real registers
logic [2:0]  cycle,next_cycle;
logic [63:0] mul_result,mul_next;
logic [1:0]   state, next_state;
logic  mul_rdy_i;

assign tmp_mul1 = src1 * (cycle == 3'h0 ? src2[31:28] 
                       : (cycle == 3'h1) ? src2[27:24]
                       : (cycle == 3'h2) ? src2[23:20]
                       : (cycle == 3'h3) ? src2[19:16]
                       : (cycle == 3'h4) ? src2[15:12]
                       : (cycle == 3'h5) ? src2[11:8]
                       : (cycle == 3'h6) ? src2[7:4]
                       : src2[3:0]);

assign shifted = (cycle == 3'h0 ? 64'h0 : {mul_result[59:0], 4'b0000});
assign tmp_mul = tmp_mul1 + shifted;
assign des_hig = mul_result[63:32];
assign des_low = mul_result[31:0];

always_ff @(posedge clk or negedge rstn)
begin
   if (!rstn) begin
      data_valid_i <= '0;
      state        <= WAIT_CMD;
      cycle        <= 3'b0;
      mul_result   <= 65'b0;
      mul_rdy_o    <= 1'b0;
      src1         <= 32'h0;
      src2         <= 32'h0;
   end else begin
     data_valid_i <= data_valid; // for edge detection
     cycle        <= next_cycle;
     state        <= next_state;

     mul_result   <= mul_next;
     mul_rdy_o    <= mul_rdy_i;
     if(data_valid && state== WAIT_CMD ) begin
        src1   <= (Din1[32] == 1'b1) ? (32'hFFFF_FFFF ^ Din1[31:0])+1 : Din1[31:0];
        src2   <= (Din2[32] == 1'b1) ? (32'hFFFF_FFFF ^ Din2[31:0])+1 : Din2[31:0];
     end
     if(state== WAIT_DONE ) begin
	// If Number is negative, then do 2's complement
        if(Din1[32] ^ Din2[32]) begin 
           mul_result <= (64'hFFFF_FFFF_FFFF_FFFF ^ mul_result[63:0]) + 1;
	end
     end else begin
	mul_result   <= mul_next;
     end
   end
end

always_comb
begin
     mul_rdy_i = 0;
     next_cycle   = cycle;
     next_state   = state;
     mul_next     = mul_result;
     case(state)
     WAIT_CMD: if(data_valid && !data_valid_i)  begin // Start only on active High Edge
	     mul_next   = tmp_mul;
	     next_cycle = 0;
	     next_state = WAIT_COMP;
	 end
     // WAIT for Computation
     WAIT_COMP:  
	begin
	   mul_next   = tmp_mul;
	   next_cycle = cycle +1;
	   if(cycle == 7) begin
	      next_state  = WAIT_DONE;
           end else begin
	      next_cycle = cycle +1;
	   end
	end
     WAIT_DONE:  
	begin
           mul_rdy_i = 1'b1;
	   next_state  = WAIT_CMD;
	end
    endcase
end

endmodule

