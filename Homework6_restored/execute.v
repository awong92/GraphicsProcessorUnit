`include "global_def.h"

module Execute(
  I_CLOCK,
  I_LOCK,
  I_PC,
  I_Opcode,
  I_Src1Value,
  I_Src2Value,
  I_DestValue,
  I_DestRegIdx,
  I_VSrc1Value,
  I_VSrc2Value,
  I_VDestValue,
  I_Imm,
  I_FetchStall,
  I_DepStall,
  I_FRAMESTALL,
  O_LOCK,
  O_ALUOut,
  O_VALUOut,
  O_Opcode,
  O_DestRegIdx,
  O_DestValue,
  O_FetchStall,
  O_DepStall
);

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
//
// Inputs from the decode stage
input I_CLOCK;
input I_LOCK;
input [`PC_WIDTH-1:0] I_PC;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input [5:0] I_DestRegIdx;
input [`REG_WIDTH-1:0] I_Src1Value;
input [`REG_WIDTH-1:0] I_Src2Value;
input [`REG_WIDTH-1:0] I_Imm;
input I_FetchStall;
input I_DepStall;
input [`REG_WIDTH-1:0] I_DestValue;
input I_FRAMESTALL;

input [`VREG_WIDTH-1:0] I_VSrc1Value;
input [`VREG_WIDTH-1:0] I_VSrc2Value;
input [`VREG_WIDTH-1:0] I_VDestValue;
// Outputs to the memory stage
output reg O_LOCK;
output reg [`REG_WIDTH-1:0] O_ALUOut;
output reg [`VREG_WIDTH-1:0] O_VALUOut;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg [`REG_WIDTH-1:0] O_DestValue;
output reg [5:0] O_DestRegIdx;
output reg O_FetchStall;
output reg O_DepStall;

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//

/////////////////////////////////////////
// ALWAYS STATEMENT GOES HERE
/////////////////////////////////////////
//

/////////////////////////////////////////
// ## Note ##
// - Do the appropriate ALU operations.
/////////////////////////////////////////
always @(negedge I_CLOCK)
begin
  O_LOCK <= I_LOCK;
  O_Opcode <=  I_Opcode;
  O_FetchStall <= I_FetchStall;
  O_DepStall <= I_DepStall;
  O_DestRegIdx <= I_DestRegIdx;
  O_DestValue <= I_DestValue;

  if (I_LOCK == 1'b1  && I_FRAMESTALL == 0) 
  begin
	  if (!I_FetchStall&&!I_DepStall) 
		begin
			case(I_Opcode) 
				`OP_ADD_D: begin
						O_ALUOut <= I_Src1Value + I_Src2Value; 
				end
				`OP_ADDI_D: begin
						O_ALUOut <= I_Src1Value + I_Imm; 
				end
				`OP_ADDI_F: begin
						O_ALUOut <= I_Src1Value + I_Imm; 
				end

				`OP_AND_D: begin
						O_ALUOut <= I_Src1Value & I_Src2Value; 
				end
				`OP_ANDI_D: begin
						O_ALUOut <= I_Src1Value & I_Imm; 
				end
				`OP_MOV: begin
						O_ALUOut <= I_Src2Value; 
				end
				`OP_MOVI_D: begin
						O_ALUOut <= I_Imm; 
				end
				`OP_MOVI_F: begin
						O_ALUOut <= I_Imm; 
				end
				`OP_LDW:  begin
						O_ALUOut <= I_Src1Value + I_Imm; 
				end
				`OP_STW:  begin
						O_ALUOut <= I_Src1Value + I_Imm; 
				end
				`OP_BRN:  begin
						O_ALUOut <= I_PC + (I_Imm<<2); 
				end
				`OP_BRZ:  begin
						O_ALUOut <= I_PC + (I_Imm<<2); 
				end
				`OP_BRP: begin
						O_ALUOut <= I_PC + (I_Imm<<2); 
				end 
				`OP_BRNZ: begin
						O_ALUOut <= I_PC + (I_Imm<<2); 
				end 
				`OP_BRNP: begin
						O_ALUOut <= I_PC + (I_Imm<<2); 
				end 
				`OP_BRZP: begin
						O_ALUOut <= I_PC + (I_Imm<<2); 
				end 
				`OP_BRNZP: begin
						O_ALUOut <= I_PC + (I_Imm<<2); 
				end 
				`OP_JSR: begin
						O_ALUOut <= I_PC + (I_Imm<<2);
				end
				`OP_JSRR: begin
						O_ALUOut <= I_Src1Value;
				end
				`OP_JMP: begin
						O_ALUOut <= I_Src1Value; 	
				end
				`OP_VADD: begin
						O_VALUOut[15:0] <= I_VSrc1Value[15:0] + I_VSrc2Value[15:0];
						O_VALUOut[31:16] <= I_VSrc1Value[31:16] + I_VSrc2Value[31:16];
						O_VALUOut[47:32] <= I_VSrc1Value[47:32] + I_VSrc2Value[47:32];
						O_VALUOut[63:48] <= I_VSrc1Value[63:48] + I_VSrc2Value[63:48];
				end
				`OP_VMOV: begin
						O_VALUOut <= I_VSrc1Value;
				end
				`OP_VMOVI: begin
						O_VALUOut[15:0] <= I_Imm;
						O_VALUOut[31:16] <= I_Imm;
						O_VALUOut[47:32] <= I_Imm;
						O_VALUOut[63:48] <= I_Imm;
				end
				`OP_VCOMPMOV: begin
					O_ALUOut <= I_Src1Value;
				end
				`OP_VCOMPMOVI: begin
					O_ALUOut <= I_Imm;
				end
				`OP_SETCOLOR: begin
					O_VALUOut <= I_VDestValue;
				end
				`OP_SETVERTEX: begin
					O_VALUOut <= I_VDestValue;
				end
				`OP_SCALE: begin
					O_VALUOut <= I_VDestValue;
				end
				`OP_TRANSLATE: begin
					O_VALUOut <= I_VDestValue;
				end
				`OP_ROTATE: begin
					O_VALUOut <= I_VDestValue;
				end
				//VADD, VMOV, VMOVI, VCOMPMOV, VCOMPMOVI, BeginPrimitive, EndPrimitive, SetVertex, Rotate, Translate, Scale, Draw

		endcase
	 end
  end // if (I_LOCK == 1'b1)
end // always @(negedge I_CLOCK)

endmodule // module Execute
