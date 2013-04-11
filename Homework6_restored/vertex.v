`include "global_def.h"

module Vertex(
    I_CLOCK,
    I_LOCK,
    I_Opcode,
    I_ALUOut,
    O_LOCK
);

input I_CLOCK;
input I_LOCK;

output reg O_LOCK;

//TODO ADD THE VERTEX REGS AND MATRIX REGS
reg isSetVertex; 
reg isStartPrimitive;
reg isEndPrimitive;
reg isDraw;

reg [`DATA_WIDTH:0] currentMatrix [0:`REG_WIDTH]; 
reg [`DATA_WIDTH:0] vertex [0:2];

always @(posedge I_CLOCK)
begin
 
  if (I_LOCK == 1'b1)
  begin 
  end
end

always @(negedge I_CLOCK)
begin
 
  if (I_LOCK == 1'b1)
  begin 
      
  end
end

endmodule