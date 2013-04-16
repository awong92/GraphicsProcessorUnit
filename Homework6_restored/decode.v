`include "global_def.h"

module Decode(
  I_CLOCK,
  I_LOCK,
  I_PC,
  I_IR,
  I_FetchStall,
  I_WriteBackEnable,
  I_VWriteBackEnable,
  I_WriteBackRegIdx,
  I_WriteBackData,
  I_VWriteBackData,
  I_FRAMESTALL,
  O_LOCK,
  O_PC,
  O_Opcode,
  O_Src1Value,
  O_Src2Value,
  O_DestValue,
  O_DestRegIdx,
  O_VSrc1Value,
  O_VSrc2Value,
  O_VDestValue,
  O_Imm,
  O_FetchStall,
  O_DepStall,
  O_BranchStallSignal,
  O_DepStallSignal
);

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
//
// Inputs from the fetch stage
input I_CLOCK;
input I_LOCK;
input [`PC_WIDTH-1:0] I_PC;
input [`IR_WIDTH-1:0] I_IR;
input I_FetchStall;

// Inputs from the writeback stage
input I_WriteBackEnable;
input [5:0] I_WriteBackRegIdx;
input [`REG_WIDTH-1:0] I_WriteBackData;

input I_VWriteBackEnable;
input [`VREG_WIDTH-1:0] I_VWriteBackData;
input I_FRAMESTALL;

// Outputs to the execude stage
output reg O_LOCK;
output reg [`PC_WIDTH-1:0] O_PC;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg [`REG_WIDTH-1:0] O_Src1Value;
output reg [`REG_WIDTH-1:0] O_Src2Value;
output reg [`REG_WIDTH-1:0] O_DestValue;
output reg [`VREG_WIDTH-1:0] O_VSrc1Value;
output reg [`VREG_WIDTH-1:0] O_VSrc2Value;
output reg [`VREG_WIDTH-1:0] O_VDestValue;
output reg [5:0] O_DestRegIdx;
output reg [`REG_WIDTH-1:0] O_Imm;
output reg O_FetchStall;
 reg[2:0] conditionDep;

/////////////////////////////////////////
// ## Note ##
// O_DepStall: Asserted when current instruction should be waiting for data dependency resolves. 
// - Like O_FetchStall, the instruction with O_DepStall == 1 will be treated as NOP in the following stages.
/////////////////////////////////////////
output reg O_DepStall;  

// Outputs to the fetch stage
output reg O_DepStallSignal;
output reg O_BranchStallSignal;

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//
// Architectural Registers
reg [`REG_WIDTH-1:0] RF[0:`NUM_RF-1]; // Scalar Register File (R0-R7: Integer, R8-R15: Floating-point)
reg [`VREG_WIDTH-1:0] VRF[0:`NUM_VRF-1]; // Vector Register File

// Valid bits for tracking the register dependence information
reg RF_VALID[0:`NUM_RF-1]; // Valid bits for Scalar Register File
reg VRF_VALID[0:`NUM_VRF-1]; // Valid bits for Vector Register File

wire [`REG_WIDTH-1:0] Imm32; // Sign-extended immediate value
reg [2:0] ConditionalCode; // Set based on the written-back result

reg[2:0] branchCounter;

/////////////////////////////////////////
// INITIAL/ASSIGN STATEMENT GOES HERE
/////////////////////////////////////////
//
reg[7:0] trav;
reg __DepStallSignal;
initial
begin
  for (trav = 0; trav < `NUM_RF; trav = trav + 1'b1)
  begin
    RF[trav] = 0;
    RF_VALID[trav] = 1;  
  end 

  for (trav = 0; trav < `NUM_VRF; trav = trav + 1'b1)
  begin
    VRF[trav] = 0;
    VRF_VALID[trav] = 1;  
  end 

  ConditionalCode = 0;
  branchCounter = 0;
  O_PC = 0;
  O_Opcode = 0;
  O_DepStall = 0;
  __DepStallSignal = 0;
end // initial

/////////////////////////////////////////////
// ## Note ##
// __DepStallSignal: Data dependency detected (1) or not (0).
// - Keep in mind that since valid bit is only updated in negative clock
//   edge, you need to take currently written-back information, if there is, into account
//   when asserting this signal as well as valid-bit information.
/////////////////////////////////////////////
/*assign __DepStallSignal = 
  (I_LOCK == 1'b1) ? 
    ((I_IR[31:24] == `OP_ADDI_D    ) ? ((I_WriteBackEnable == 1) ? ((I_WriteBackRegIdx == I_IR[19:16]) ? (1'b0) : (RF_VALID[I_IR[19:16]] != 1)) : (RF_VALID[I_IR[19:16]] != 1)) : 
     (I_IR[31:24] == `OP_ADD_D    ) ? ((I_WriteBackEnable == 1) ? (((I_WriteBackRegIdx == I_IR[19:16]&&RF_VALID[I_IR[11:8]] != 1)||(I_WriteBackRegIdx == I_IR[11:8]&&RF_VALID[I_IR[19:16]] != 1)) ? (1'b0) : (RF_VALID[I_IR[19:16]] != 1||RF_VALID[I_IR[11:8]] != 1)) : (RF_VALID[I_IR[19:16]] != 1||RF_VALID[I_IR[11:8]] != 1)) :
     (I_IR[31:24] == `OP_ANDI_D    ) ? ((I_WriteBackEnable == 1) ? ((I_WriteBackRegIdx == I_IR[19:16]) ? (1'b0) : (RF_VALID[I_IR[19:16]] != 1)) : (RF_VALID[I_IR[19:16]] != 1)) :
     (I_IR[31:24] == `OP_AND_D    ) ? ((I_WriteBackEnable == 1) ? (((I_WriteBackRegIdx == I_IR[19:16]&&RF_VALID[I_IR[11:8]] != 1)||(I_WriteBackRegIdx == I_IR[11:8]&&RF_VALID[I_IR[19:16]] != 1)) ? (1'b0) : (RF_VALID[I_IR[19:16]] != 1||RF_VALID[I_IR[11:8]] != 1)) : (RF_VALID[I_IR[19:16]] != 1||RF_VALID[I_IR[11:8]] != 1)) :
     (I_IR[31:24] == `OP_MOV    ) ? ((I_WriteBackEnable == 1) ? ((I_WriteBackRegIdx == I_IR[11:8]) ? (1'b0) : (RF_VALID[I_IR[11:8]] != 1)) : (RF_VALID[I_IR[11:8]] != 1)) :
      (I_IR[31:24] == `OP_MOVI_D    ) ? (1'b0) :
      (I_IR[31:24] == `OP_LDW    ) ? (1'b0) :  
      (I_IR[31:24] == `OP_STW    ) ? 
     (I_IR[31:24] == `OP_BRN       ) ? (ConditionalCode != 3'b100) : 
     (I_IR[31:24] == `OP_BRZ       ) ? (ConditionalCode != 3'b010) : 
     (I_IR[31:24] == `OP_BRP       ) ? (ConditionalCode != 3'b001) : 
     (I_IR[31:24] == `OP_BRNZ       ) ? (ConditionalCode != 3'b100 && ConditionalCode != 3'b010) : 
     (I_IR[31:24] == `OP_BRNP       ) ? (ConditionalCode != 3'b100 && ConditionalCode != 3'b001) : 
     (I_IR[31:24] == `OP_BRZP       ) ? (ConditionalCode != 3'b010 && ConditionalCode != 3'b001) : 
     (I_IR[31:24] == `OP_BRNZP       ) ? (1'b1) : 
      (branchCounter<=3 && O_BranchStallSignal) ? (1'b1):
     /////////////////////////////////////////////
     // TODO: Complete other instructions
     /////////////////////////////////////////////
     (1'b0)
    ) : (1'b0);*/
/*
if (I_LOCK == 1'b1) begin    
    if (I_IR[31:24] == `OP_STW) begin
          if (RF_VALID[I_IR[19:16]] != 1||RF_VALID[I_IR[23:20]] != 1) begin
                if (RF_VALID[I_IR[19:16]] != 1 && RF_VALID[I_IR[23:20]] != 1) begin
                        assign __DepStallSignal = 1;
                end else if(RF_VALID[I_IR[19:16]] != 1 && I_WriteBackRegIdx == I_IR[19:16]) begin
                        assign __DepStallSignal = 0;
                end else if(RF_VALID[I_IR[23:20]] != 1 && I_WriteBackRegIdx == I_IR[23:20]) begin
                        assign __DepStallSignal = 0;
                end else begin
                        assign __DepStallSignal = 1;
                end
            end else begin
                assign __DepStallSignal = 0;
            end
    end
end
     
     
assign O_DepStallSignal = (__DepStallSignal & !I_WriteBackEnable);
*/
// O_BranchStallSignal: Branch instruction detected (1) or not (0).


/////////////////////////////////////////
// ALWAYS STATEMENT GOES HERE
/////////////////////////////////////////
//

/////////////////////////////////////////
// ## Note ##
// First half clock cycle to write data back into the register file 
// 1. To write data back into the register file
// 2. Update Conditional Code to the following branch instruction to refer
/////////////////////////////////////////
always @(posedge I_CLOCK)
begin
 
  if (I_LOCK == 1'b1  && I_FRAMESTALL == 0)
  begin 
   if (I_WriteBackEnable==1) begin                  //Write back data if necessary
        RF[I_WriteBackRegIdx] <= I_WriteBackData;   
        if (I_WriteBackData[15]==1)begin        //Find conditional code
            ConditionalCode = 4;
        end else if(I_WriteBackData>0) begin
            ConditionalCode = 1;
        end else begin
            ConditionalCode = 2;
        end
    end

    if (I_VWriteBackEnable==1) begin                    //Write back data if necessary
        VRF[I_WriteBackRegIdx] <= I_VWriteBackData;   
    end
    
    if (I_IR[31:24] == `OP_JSR || I_IR[31:24] == `OP_JSRR)          //Write return register
        RF[7] <= I_PC;
    else
    ;
    end // if (I_LOCK == 1'b1)  
    
    if (I_IR[31:24] == `OP_BRN||I_IR[31:24] == `OP_BRZ||I_IR[31:24] == `OP_BRP||I_IR[31:24] == `OP_BRNZ||I_IR[31:24] == `OP_BRNP||I_IR[31:24] == `OP_BRZP)begin
        if (!O_BranchStallSignal) begin
            branchCounter=0;
        end
        branchCounter = branchCounter + 1;
    end
    
        O_BranchStallSignal = 
  (I_LOCK == 1'b1) ? 
    ((I_IR[31:24] == `OP_BRN  ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRZ  ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRP  ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRNZ ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRNP ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRZP ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRNZP) ? (1'b1) : 
     (I_IR[31:24] == `OP_JMP  ) ? (1'b1) : 
     (I_IR[31:24] == `OP_JSR  ) ? (1'b1) : 
     (I_IR[31:24] == `OP_JSRR ) ? (1'b1) : 
     (1'b0)
    ) : (1'b0);
    
    if (I_LOCK == 1'b1  && I_FRAMESTALL == 0) begin    
        if (I_IR[31:24] == `OP_STW) begin
              if (RF_VALID[I_IR[19:16]] != 1||RF_VALID[I_IR[23:20]] != 1) begin
                    if (RF_VALID[I_IR[19:16]] != 1 && RF_VALID[I_IR[23:20]] != 1) begin
                            __DepStallSignal = 1;
                    end else if(RF_VALID[I_IR[19:16]] != 1 && I_WriteBackRegIdx == I_IR[19:16]) begin
                            __DepStallSignal = 0;
                    end else if(RF_VALID[I_IR[23:20]] != 1 && I_WriteBackRegIdx == I_IR[23:20]) begin
                            __DepStallSignal = 0;
                    end else begin
                            __DepStallSignal = 1;
                    end
                end else begin
                    __DepStallSignal = 0;
                end
        end else if (I_IR[31:24] == `OP_VADD) begin
              if (VRF_VALID[I_IR[13:8]] != 1||VRF_VALID[I_IR[5:0]] != 1) begin
                    if (VRF_VALID[I_IR[13:8]] != 1 && VRF_VALID[I_IR[5:0]] != 1) begin
                            __DepStallSignal = 1;
                    end else if(VRF_VALID[I_IR[13:8]] != 1 && I_WriteBackRegIdx == I_IR[5:0]) begin
                            __DepStallSignal = 0;
                    end else if(VRF_VALID[I_IR[5:0]] != 1 && I_WriteBackRegIdx == I_IR[5:0]) begin
                            __DepStallSignal = 0;
                    end else begin
                            __DepStallSignal = 1;
                    end
                end else begin
                    __DepStallSignal = 0;
                end
        end else if ((I_IR[31:24] == `OP_ADD_D )|| (I_IR[31:24] == `OP_AND_D)) begin
              if (RF_VALID[I_IR[19:16]] != 1||RF_VALID[I_IR[11:8]] != 1) begin
                    if (RF_VALID[I_IR[19:16]] != 1 && RF_VALID[I_IR[11:8]] != 1) begin
                            __DepStallSignal = 1;
                    end else if(RF_VALID[I_IR[19:16]] != 1 && I_WriteBackRegIdx == I_IR[19:16]) begin
                            __DepStallSignal = 0;
                    end else if(RF_VALID[I_IR[11:8]] != 1 && I_WriteBackRegIdx == I_IR[11:8]) begin
                            __DepStallSignal = 0;
                    end else begin
                            __DepStallSignal = 1;
                    end
                end else begin
                    __DepStallSignal = 0;
                end
        end else if (I_IR[31:24] == `OP_ADDI_F||I_IR[31:24] == `OP_ADDI_D||I_IR[31:24] == `OP_ANDI_D) begin
              if (RF_VALID[I_IR[19:16]] != 1) begin
                    if(RF_VALID[I_IR[19:16]] != 1 && I_WriteBackRegIdx == I_IR[19:16]) begin
                            __DepStallSignal = 0;
                    end else begin
                            __DepStallSignal = 1;
                    end
                end else begin
                    __DepStallSignal = 0;
                end
        end else if (I_IR[31:24] == `OP_MOV) begin
              if (RF_VALID[I_IR[11:8]] != 1) begin
                    if(RF_VALID[I_IR[11:8]] != 1 && I_WriteBackRegIdx == I_IR[11:8]) begin
                            __DepStallSignal = 0;
                    end else begin
                            __DepStallSignal = 1;
                    end
                end else begin
                    __DepStallSignal = 0;
                end     
        end else if (I_IR[31:24] == `OP_VMOV) begin
              if (VRF_VALID[I_IR[13:8]] != 1) begin
                    if(VRF_VALID[I_IR[13:8]] != 1 && I_WriteBackRegIdx == I_IR[13:8]) begin
                            __DepStallSignal = 0;
                    end else begin
                            __DepStallSignal = 1;
                    end
                end else begin
                    __DepStallSignal = 0;
                end
        end else if (I_IR[31:24] == `OP_VCOMPMOV) begin
              if (RF_VALID[I_IR[11:8]] != 1) begin
                    if(RF_VALID[I_IR[11:8]] != 1 && I_WriteBackRegIdx == I_IR[11:8]) begin
                            __DepStallSignal = 0;
                    end else begin
                            __DepStallSignal = 1;
                    end
                end else begin
                    __DepStallSignal = 0;
                end     
        end else if (I_IR[31:24] == `OP_LDW) begin
              if (RF_VALID[I_IR[19:16]] != 1) begin
                    if(RF_VALID[I_IR[19:16]] != 1 && I_WriteBackRegIdx == I_IR[19:16]) begin
                            __DepStallSignal = 0;
                    end else begin
                            __DepStallSignal = 1;
                    end
                end else begin
                    __DepStallSignal = 0;
                end
        end else if (I_IR[31:24] == `OP_JMP || I_IR[31:24] == `OP_JSRR) begin
              if (RF_VALID[I_IR[19:16]] != 1) begin
                    if(RF_VALID[I_IR[19:16]] != 1 && I_WriteBackRegIdx == I_IR[19:16]) begin
                            __DepStallSignal = 0;
                    end else begin
                            __DepStallSignal = 1;
                    end
                end else begin
                    __DepStallSignal = 0;
                end
        end else if ((I_IR[31:24] == `OP_BRN||I_IR[31:24] == `OP_BRZ||I_IR[31:24] == `OP_BRP||I_IR[31:24] == `OP_BRNZ||I_IR[31:24] == `OP_BRNP||I_IR[31:24] == `OP_BRZP)&&branchCounter<4) begin
            __DepStallSignal = 1;
            conditionDep = 1;
        end else if (I_IR[31:24] == `OP_BRN) begin
            __DepStallSignal = (ConditionalCode != 3'b100);
                        conditionDep = 2;

        end else if (I_IR[31:24] == `OP_BRZ) begin
            __DepStallSignal = (ConditionalCode != 3'b010);
            conditionDep = 3;

            end else if (I_IR[31:24] == `OP_BRP) begin
            __DepStallSignal = (ConditionalCode != 3'b001);
            conditionDep = 4;

            end else if (I_IR[31:24] == `OP_BRNZ) begin
            __DepStallSignal = (ConditionalCode != 3'b100 && ConditionalCode != 3'b010);
        end else if (I_IR[31:24] == `OP_BRNP) begin
            __DepStallSignal = (ConditionalCode != 3'b100 && ConditionalCode != 3'b001);
        end else if (I_IR[31:24] == `OP_BRZP) begin
            __DepStallSignal = (ConditionalCode != 3'b010 && ConditionalCode != 3'b001);
        end else if (I_IR[31:24] == `OP_BRNZP) begin
            __DepStallSignal = 1;
        end else begin
            __DepStallSignal = 0;
        end
        
    end

    O_DepStallSignal = __DepStallSignal;
        
    if (branchCounter==4)begin
            if (__DepStallSignal) begin
                O_BranchStallSignal = 0;
                O_DepStallSignal = 0;
            end
            branchCounter = 0;
    end

    
end // always @(posedge I_CLOCK)

/////////////////////////////////////////
// ## Note ##
// Second half clock cycle to read data from the register file
// 1. To read data from the register file
// 2. To update valid bit for the corresponding register (for both writeback instruction and current instruction) 
/////////////////////////////////////////
always @(negedge I_CLOCK)
begin
  O_LOCK <= I_LOCK;
  O_FetchStall <= I_FetchStall;
O_DepStall = __DepStallSignal;

  if (I_FetchStall==0&&O_DepStallSignal==0) begin
      if (I_LOCK == 1'b1  && I_FRAMESTALL == 0)
      begin
        O_PC <= I_PC;
        O_Src1Value <= RF[I_IR[19:16]];
        O_Src2Value <= RF[I_IR[11:8]];  
        O_DestValue <= RF[I_IR[11:8]];
        O_Opcode <= I_IR[31:24];
        
        if (I_IR[31:24] == `OP_MOV || I_IR[31:24] == `OP_MOVI_D|| I_IR[31:24] == `OP_MOVI_F)begin
            O_DestRegIdx = I_IR[19:16];
        end else begin
            O_DestRegIdx = I_IR[23:20];
        end

        O_Imm <= I_IR[15:0]; 
        
        if (I_IR[31:24] == `OP_STW)
            O_DestValue <= RF[I_IR[23:20]];

        if (I_IR[31:24] == `OP_ADDI_F||I_IR[31:24] == `OP_ADDI_D || I_IR[31:24] == `OP_ADD_D || I_IR[31:24] == `OP_AND_D || I_IR[31:24] == `OP_ANDI_D || I_IR[31:24] == `OP_MOVI_F ||I_IR[31:24] == `OP_MOVI_D || I_IR[31:24] == `OP_MOV || I_IR[31:24] == `OP_LDW)
            RF_VALID[O_DestRegIdx]<=0;
    
        //VADD, VMOV, VMOVI, VCOMPMOV, VCOMPMOVI, BeginPrimitive, EndPrimitive, SetVertex, Rotate, Translate, Scale, Draw
        if(I_IR[31:24] == `OP_VADD)
        begin
            O_DestRegIdx = I_IR[21:16];
            VRF_VALID[O_DestRegIdx] = 0;
            O_VSrc1Value <= VRF[I_IR[13:8]];
            O_VSrc2Value <= VRF[I_IR[5:0]];
        end
        if(I_IR[31:24] == `OP_VMOV)
        begin
            O_DestRegIdx = I_IR[21:16];
            VRF_VALID[O_DestRegIdx] = 0;
            O_VSrc1Value <= VRF[I_IR[13:8]];
        end
        if(I_IR[31:24] == `OP_VMOVI)
        begin
            O_DestRegIdx = I_IR[21:16];
            VRF_VALID[O_DestRegIdx] = 0;
            O_Imm <= I_IR[15:0];
        end
        if(I_IR[31:24] == `OP_VCOMPMOV)
        begin
            O_DestRegIdx = I_IR[21:16];
            VRF_VALID[O_DestRegIdx] = 0;
            O_DestValue <= I_IR[23:22];
            O_Src1Value <= I_IR[11:8];
        end
        if(I_IR[31:24] == `OP_VCOMPMOVI)
        begin
            O_DestRegIdx = I_IR[21:16];
            VRF_VALID[O_DestRegIdx] = 0;
            O_DestValue <= I_IR[23:22];
            O_Imm <= I_IR[15:0];
        end
        if(I_IR[31:24] == `OP_BEGINPRIMITIVE || I_IR[31:24] == `OP_ENDPRIMITIVE || I_IR[31:24] == `OP_DRAW || I_IR[31:24] == `OP_FLUSH || I_IR[31:24] == `OP_PUSHMATRIX || I_IR[31:24] == `OP_POPMATRIX)
        begin
        end
        if(I_IR[31:24] == `OP_SETVERTEX || I_IR[31:24] == `OP_SETCOLOR || I_IR[31:24] == `OP_ROTATE || I_IR[31:24] == `OP_TRANSLATE || I_IR[31:24] == `OP_SCALE) begin
            O_VDestValue <= VRF[I_IR[21:16]];
        end
      end // if (I_LOCK == 1'b1)
    end
    
    
        if (I_WriteBackEnable==1) begin                 //Write back data if necessary
            RF_VALID[I_WriteBackRegIdx]<=1;
        end
            
        if (I_VWriteBackEnable==1) begin                    //Write back data if necessary
            VRF_VALID[I_WriteBackRegIdx]<=1;
        end
    
end // always @(negedge I_CLOCK)

/////////////////////////////////////////
// COMBINATIONAL LOGIC GOES HERE
/////////////////////////////////////////
//
SignExtension SE0(.In(I_IR[15:0]), .Out(Imm32));

endmodule // module Decode
