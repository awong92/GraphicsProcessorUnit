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
  O_BranchPC,
  O_BranchAddrSelect,
  O_FetchStall,
  O_DepStall,
  O_LEDR,
  O_LEDG,
  O_HEX0,
  O_HEX1,
  O_HEX2,
  O_HEX3
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
input [3:0] I_DestRegIdx;
input I_FetchStall;
input I_DepStall;
input [`REG_WIDTH-1:0] I_DestValue;
input [`VREG_WIDTH-1:0] I_VALUOut;
input I_FRAMESTALL;

// Outputs to the writeback stage
output reg O_LOCK;
output reg [`REG_WIDTH-1:0] O_ALUOut;
output reg [`VREG_WIDTH-1:0] O_VALUOut;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg [3:0] O_DestRegIdx;
output reg [`REG_WIDTH-1:0] O_MemOut;
output reg O_FetchStall;
output reg O_DepStall;

// Outputs to the fetch stage
output reg [`PC_WIDTH-1:0] O_BranchPC;
output reg O_BranchAddrSelect;

// Outputs for debugging
output [9:0] O_LEDR;
output [7:0] O_LEDG;
output [6:0] O_HEX0, O_HEX1, O_HEX2, O_HEX3;

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
  O_DestRegIdx <= I_DestRegIdx;
  O_ALUOut <= I_ALUOut;
  O_VALUOut <= I_VALUOut;
  O_Opcode <= I_Opcode;
  
  
  if (I_LOCK == 1'b1  && I_FRAMESTALL == 0)
  begin
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

/////////////////////////////////////////
// ## Note ##
// Simple implementation of Memory-mapped I/O
// - The value stored at dedicated location will be expressed 
//   by the corresponding H/W.
//   - LEDR: Address 1020 (0x3FC)
//   - LEDG: Address 1021 (0x3FD)
//   - HEX : Address 1022 (0x3FE)
/////////////////////////////////////////
// Create and connect HEX register 
reg [15:0] HexOut;
SevenSeg sseg0(.OUT(O_HEX3), .IN(HexOut[15:12]));
SevenSeg sseg1(.OUT(O_HEX2), .IN(HexOut[11:8]));
SevenSeg sseg2(.OUT(O_HEX1), .IN(HexOut[7:4]));
SevenSeg sseg3(.OUT(O_HEX0), .IN(HexOut[3:0]));

// Create and connect LEDR, LEDG registers 
reg [9:0] LedROut;
reg [7:0] LedGOut;

always @(negedge I_CLOCK)
begin
  if (I_LOCK == 0) begin
    HexOut <= 16'hDEAD;
    LedGOut <= 8'b11111111;
    LedROut <= 10'b1111111111;
  end else begin // if (I_LOCK == 0) begin
    if ((I_FetchStall == 1'b0) && (I_DepStall == 1'b0)) begin
      if (I_Opcode == `OP_STW) begin
        if (I_ALUOut[9:0] == `ADDRHEX)
          HexOut <= I_DestValue;
        else if (I_ALUOut[9:0] == `ADDRLEDR)
          LedROut <= I_DestValue;
        else if (I_ALUOut[9:0] == `ADDRLEDG)
          LedGOut <= I_DestValue;
      end // if (I_Opcode == `OP_STW) begin
    end // if ((I_FetchStall == 1'b0) && (I_DepStall == 1'b0)) begin
  end // if (I_LOCK == 0) begin
end // always @(negedge I_CLOCK)

assign O_LEDR = LedROut;
assign O_LEDG = LedGOut;


endmodule // module Memory
