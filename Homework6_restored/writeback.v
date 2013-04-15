`include "global_def.h"

module Writeback(
  I_CLOCK,
  I_LOCK,
  I_Opcode,
  I_ALUOut,
  I_VALUOut,
  I_MemOut,
  I_DestRegIdx,
  I_FetchStall,
  I_DepStall,
  O_WriteBackEnable,
  O_WriteBackRegIdx,
  O_WriteBackData,
  O_VWriteBackData,
  O_VWriteBackEnable,
  O_Opcode
 );

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
//
// Inputs from the memory stage
input I_CLOCK;
input I_LOCK;
input I_FetchStall;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input [3:0] I_DestRegIdx;
input [`REG_WIDTH-1:0] I_ALUOut;
input [`REG_WIDTH-1:0] I_MemOut;
input I_DepStall;
input [`VREG_WIDTH-1:0] I_VALUOut;

// Outputs to the decode stage
output O_WriteBackEnable;
output [5:0] O_WriteBackRegIdx;
output [`REG_WIDTH-1:0] O_WriteBackData;
output [`VREG_WIDTH-1:0] O_VWriteBackData;
output O_VWriteBackEnable;
input [`OPCODE_WIDTH-1:0] O_Opcode;


//Reg file?
/////////////////////////////////////////
// ## Note ##
// - Assign output signals depending on opcode.
// - A few examples are provided.
/////////////////////////////////////////
assign O_Opcode = I_Opcode;

assign O_WriteBackEnable = 
  ((I_LOCK == 1'b1) && (I_FetchStall == 1'b0)) ? 
    ((I_DepStall == 1'b0) ?
      ((I_Opcode == `OP_ADD_D ) ? (1'b1) :
       (I_Opcode == `OP_ADDI_D) ? (1'b1) :
       (I_Opcode == `OP_AND_D) ? (1'b1) :
       (I_Opcode == `OP_ANDI_D) ? (1'b1) :
       (I_Opcode == `OP_MOV) ? (1'b1) :
       (I_Opcode == `OP_MOVI_D) ? (1'b1) :
		 (I_Opcode == `OP_LDW) ? (1'b1) :
       (I_Opcode == `OP_STW) ? (1'b0) :
       (I_Opcode == `OP_JMP) ? (1'b0) :
       (I_Opcode == `OP_JSR) ? (1'b0) :
		 (I_Opcode == `OP_BRN) ? (1'b0) :
		 (I_Opcode == `OP_BRZ) ? (1'b0) :
		 (I_Opcode == `OP_BRP) ? (1'b0) :
		 (I_Opcode == `OP_BRNZ) ? (1'b0) :
		 (I_Opcode == `OP_BRNP) ? (1'b0) :
		 (I_Opcode == `OP_BRZP) ? (1'b0) :
		 (I_Opcode == `OP_BRNZP) ? (1'b0) :
       (I_Opcode == `OP_JSRR  ) ? (1'b0) : 
       (1'b0)
      ) : (1'b0)
    ) : (1'b0);

assign O_WriteBackRegIdx = 
  ((I_LOCK == 1'b1) && (I_FetchStall == 1'b0)) ? 
    ((I_DepStall == 1'b0) ?
      ((I_Opcode == `OP_ADD_D ) ? (I_DestRegIdx) :
       (I_Opcode == `OP_ADDI_D) ? (I_DestRegIdx) :
		 (I_Opcode == `OP_AND_D) ? (I_DestRegIdx) :
       (I_Opcode == `OP_ANDI_D) ? (I_DestRegIdx) :
       (I_Opcode == `OP_MOV) ? (I_DestRegIdx) :
       (I_Opcode == `OP_MOVI_D) ? (I_DestRegIdx) :
		 (I_Opcode == `OP_LDW) ? (I_DestRegIdx) :
       (I_Opcode == `OP_LDB   ) ? (I_DestRegIdx) : 
		 (I_Opcode == `OP_VADD) ? (I_DestRegIdx) :
       (I_Opcode == `OP_VMOV) ? (I_DestRegIdx) :
       (I_Opcode == `OP_VMOVI) ? (I_DestRegIdx) :
		 (I_Opcode == `OP_VCOMPMOV) ? (I_DestRegIdx) :
       (I_Opcode == `OP_VCOMPMOVI   ) ? (I_DestRegIdx) : 
       (4'h0)
      ) : (1'b0)
    ) : (1'b0);

assign O_WriteBackData = 
  ((I_LOCK == 1'b1) && (I_FetchStall == 1'b0)) ? 
    ((I_DepStall == 1'b0) ?
      ((I_Opcode == `OP_ADD_D ) ? (I_ALUOut) :
       (I_Opcode == `OP_ADDI_D) ? (I_ALUOut) :
		 (I_Opcode == `OP_AND_D) ? (I_ALUOut) :
       (I_Opcode == `OP_ANDI_D) ? (I_ALUOut) :
       (I_Opcode == `OP_MOV) ? (I_ALUOut) :
       (I_Opcode == `OP_MOVI_D) ? (I_ALUOut) :
		 (I_Opcode == `OP_LDW) ? (I_MemOut) :
       (I_Opcode == `OP_LDB   ) ? (I_MemOut) : 
       (16'h00000000)
      ) : (1'b0)
    ) : (1'b0);
	 
assign O_VWriteBackEnable = 
  ((I_LOCK == 1'b1) && (I_FetchStall == 1'b0)) ? 
    ((I_DepStall == 1'b0) ?
      ((I_Opcode == `OP_VADD ) ? (1'b1) :
       (I_Opcode == `OP_VMOV) ? (1'b1) :
       (I_Opcode == `OP_VMOVI) ? (1'b1) :
       (I_Opcode == `OP_VCOMPMOV) ? (1'b1) :
       (I_Opcode == `OP_VCOMPMOVI) ? (1'b1) :
       (1'b0)
      ) : (1'b0)
    ) : (1'b0);
	 
assign O_VWriteBackData = 
  ((I_LOCK == 1'b1) && (I_FetchStall == 1'b0)) ? 
    ((I_DepStall == 1'b0) ?
      ((I_Opcode == `OP_VADD ) ? (I_VALUOut) :
       (I_Opcode == `OP_VMOV) ? (I_VALUOut) :
		 (I_Opcode == `OP_VMOVI) ? (I_VALUOut) :
       (I_Opcode == `OP_VCOMPMOV) ? (I_VALUOut) :
       (I_Opcode == `OP_VCOMPMOVI) ? (I_VALUOut) :
       (64'h0000000000000)
      ) : (1'b0)
    ) : (1'b0);

endmodule // module Writeback
