`include "global_def.h"

module Memory(
  I_CLOCK,
  I_LOCK,
  I_ALUOut,
  I_VALUOut,
  I_Opcode,
  I_DestRegIdx,
  I_FetchStall,
  I_DepStall,
  I_DestValue,
  I_FRAMESTALL,
  O_LOCK,
  O_ALUOut,
  O_VALUOut,
  O_Opcode,
  O_MemOut,
  O_DestRegIdx,
  O_DestValue,
  O_BranchPC,
  O_BranchAddrSelect,
  O_FetchStall,
  O_DepStall

);

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
//
// Inputs from the execute stage
input I_CLOCK;
input I_LOCK;
input [`REG_WIDTH-1:0] I_ALUOut;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input [5:0] I_DestRegIdx;
input I_FetchStall;
input I_DepStall;
input [`REG_WIDTH-1:0] I_DestValue;
input [`VREG_WIDTH-1:0] I_VALUOut;
input I_FRAMESTALL;

// Outputs to the writeback stage
output reg O_LOCK;
output reg [`REG_WIDTH-1:0] O_ALUOut;
output reg [`REG_WIDTH-1:0] O_DestValue;
output reg [`VREG_WIDTH-1:0] O_VALUOut;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg [5:0] O_DestRegIdx;
output reg [`REG_WIDTH-1:0] O_MemOut;
output reg O_FetchStall;
output reg O_DepStall;

// Outputs to the fetch stage
output reg [`PC_WIDTH-1:0] O_BranchPC;
output reg O_BranchAddrSelect;


/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//
reg[`DATA_WIDTH-1:0] DataMem[0:`INST_MEM_SIZE-1];

/////////////////////////////////////////
// INITIAL STATEMENT GOES HERE
/////////////////////////////////////////
//
initial 
begin
  $readmemh("data.hex", DataMem);
end

/////////////////////////////////////////
// ALWAYS STATEMENT GOES HERE
/////////////////////////////////////////
//

/////////////////////////////////////////
// ## Note ##
// 1. Do the appropriate memory operations.
// 2. Provide Branch Target Address and Selection Signal to the fetch stage.
/////////////////////////////////////////
always @(negedge I_CLOCK)
begin
  O_LOCK <= I_LOCK;
  O_FetchStall <= I_FetchStall;
  O_DepStall <= I_DepStall;

  
  
  if (I_LOCK == 1'b1  && I_FRAMESTALL == 0)
  begin
    O_DestRegIdx <= I_DestRegIdx;
  O_ALUOut <= I_ALUOut;
  O_VALUOut <= I_VALUOut;
  O_Opcode <= I_Opcode;
  O_DestValue <= I_DestValue;
	if (!I_FetchStall&&!I_DepStall) begin
		if(I_Opcode==`OP_BRN || I_Opcode==`OP_BRZ ||I_Opcode==`OP_BRP ||I_Opcode==`OP_BRNZ ||I_Opcode==`OP_BRNZP ||I_Opcode==`OP_BRNP ||I_Opcode==`OP_BRZP ||I_Opcode==`OP_JMP ||I_Opcode==`OP_JSRR||I_Opcode==`OP_JSR) begin
			 O_BranchAddrSelect <= 1'b1;
			 O_BranchPC <= I_ALUOut;
		end else begin
				 O_BranchAddrSelect <= 1'b0;
		end
		
		if (I_Opcode==`OP_LDW) begin
			O_MemOut = DataMem[I_ALUOut];
		end else begin
			O_MemOut = 0;
		end
		
		if (I_Opcode==`OP_STW) begin
			DataMem[I_ALUOut] <= I_DestValue;
		end
	end else
		O_BranchAddrSelect <= 1'b0;
  end else // if (I_LOCK == 1'b1)
  begin
    O_BranchAddrSelect <= 1'b0;
  end // if (I_LOCK == 1'b1)
end // always @(negedge I_CLOCK)



endmodule // module Memory
