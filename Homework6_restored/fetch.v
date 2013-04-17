`include "global_def.h"

module Fetch(
  I_CLOCK,
  I_LOCK,
  I_BranchPC,
  I_BranchAddrSelect,
  I_BranchStallSignal,
  I_DepStallSignal,
  I_FRAMESTALL,
  O_LOCK,
  O_PC,
  O_IR,
  O_FetchStall
);

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
//
// Inputs from high-level module (lg_highlevel)
input I_CLOCK;
input I_LOCK;

// Inputs from the memory stage 
input [`PC_WIDTH-1:0] I_BranchPC; // Branch Target Address
input I_BranchAddrSelect; // Asserted only when Branch Target Address resolves

// Inputs from the decode stage
input I_BranchStallSignal; // Asserted from when branch instruction is decode to when Branch Target Address resolves 
input I_DepStallSignal; // Asserted when register dependency is detected
input I_FRAMESTALL;

// Outputs to the decode stage
output reg O_LOCK;
output reg [`PC_WIDTH-1:0] O_PC;
output reg [`IR_WIDTH-1:0] O_IR;

/////////////////////////////////////////
// ## Note ##
// O_FetchStall: Asserted when fetch stage is not updating FE/DE latch. 
// - The instruction with O_FetchStall == 1 will be treated as NOP in the following stages
/////////////////////////////////////////
output reg O_FetchStall; 
 
/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//
reg[`INST_WIDTH-1:0] InstMem[0:`INST_MEM_SIZE-1];
reg[`PC_WIDTH-1:0] PC;  
reg [1:0]stall;
reg [2:0]counter;

/////////////////////////////////////////
// INITIAL/ASSIGN STATEMENT GOES HERE
/////////////////////////////////////////
//
initial 
begin
  $readmemh("translate.hex", InstMem);
  PC = 16'h0;

  O_LOCK = 1'b0;
  O_PC = 16'h4;
  O_IR = 32'hFF000000;
  O_FetchStall = 0;
  stall = 0;
end

/////////////////////////////////////////
// ALWAYS STATEMENT GOES HERE
/////////////////////////////////////////

/////////////////////////////////////////
// ## Note ##
// 1. Update output values (O_FetchStall, O_PC, O_IR) and PC.
// 2. You should be careful about STALL signals.
/////////////////////////////////////////
always @(negedge I_CLOCK)
begin      
  O_LOCK <= I_LOCK;

 /* if (I_BranchStallSignal==1&&I_DepStallSignal==1)begin			//waiting for info about branch
   stall=1;
  end
  
  if (stall==1) begin
		counter=counter+1;
  end
  
  if (stall==1 && I_BranchStallSignal==1 && I_DepStallSignal==0)begin			//Branch moving forward
   stall=2;
  end
  
	 if (stall==1 && counter>3)begin			//Branch not moving forward
		stall=0;
		counter=0;
	  end
  
  
  if (I_BranchStallSignal==0 && I_DepStallSignal==1 && stall==0)begin			//Dependency Stall
   stall=3;
  end else if (I_BranchStallSignal==0 && I_DepStallSignal==0 && stall==3) begin
	stall=0;
  end

  
  if(stall==1)begin
  	O_FetchStall = 0;
  end else if (stall==2) begin
    O_FetchStall = 1;
  end else if (stall==3) begin
    O_FetchStall = 0;
  end else if (stall==0) begin
    O_FetchStall = 0;
  end else if (stall==4) begin
	 stall=0;
    O_FetchStall = 1;
  end


*/


if (I_BranchStallSignal==1&&I_DepStallSignal==1)begin
	stall = 1;
end

if (I_BranchStallSignal==1&&I_DepStallSignal==0) begin
	stall = 2;
	O_FetchStall = 1;
end else if (stall==1&&I_BranchStallSignal==0&&I_DepStallSignal==0) begin
	stall = 0;
end
 
if (stall == 2) begin
	O_FetchStall = 1;
	if (I_BranchAddrSelect==1) begin
			O_FetchStall = 0;
	end
	
	
end
  
  if ((stall==0 &&!I_DepStallSignal)||I_BranchAddrSelect) begin
	  stall = 0;
	  O_FetchStall = 0;
	  if (I_LOCK == 0  && I_FRAMESTALL == 0)
	  begin
		 PC <= 0;
		 O_IR <= InstMem[0];
		 O_PC <= 0;
	  end else // if (I_LOCK == 0)
	  begin
		if (I_BranchAddrSelect==1) begin
			O_IR = InstMem[I_BranchPC[`PC_WIDTH-1:2]];
			PC = I_BranchPC;
			PC = PC + 4;
			O_PC <= PC;
		end else begin
			O_IR <= InstMem[PC[`PC_WIDTH-1:2]];
			PC = PC + 4;
			O_PC <= PC;
		end
	  end // if (I_LOCK == 0)
	end
end // always @(negedge I_CLOCK)

endmodule // module Fetch
