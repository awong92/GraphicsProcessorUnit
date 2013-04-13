`include "global_def.h"

`timescale 1ns / 1ps

module lg_highlevel(
  // Clock Input	 
  CLOCK_27,     // 27 MHz
  CLOCK_50,     // 50 MHz
  // Push Button
  KEY,          //	Pushbutton[3:0]
  // DPDT Switch
  SW,           // Toggle Switch[9:0]
  // 7-SEG Dispaly
  HEX0,         // Seven Segment Digit 0
  HEX1,         // Seven Segment Digit 1
  HEX2,         // Seven Segment Digit 2
  HEX3,         // Seven Segment Digit 3
  // LED
  LEDG,         // LED Green[7:0]
  LEDR,         // LED Red[9:0]
  // VGA
  VGA_HS,       // VGA H_SYNC
  VGA_VS,       // VGA V_SYNC
  VGA_R,        // VGA Red[3:0]
  VGA_G,        // VGA Green[3:0]
  VGA_B,        // VGA Blue[3:0]
  // SRAM Interface
  SRAM_DQ,      //	SRAM Data bus 16 Bits
  SRAM_ADDR,    //	SRAM Address bus 18 Bits
  SRAM_UB_N,    //	SRAM High-byte Data Mask 
  SRAM_LB_N,    //	SRAM Low-byte Data Mask 
  SRAM_WE_N,    //	SRAM Write Enable
  SRAM_CE_N,    //	SRAM Chip Enable
  SRAM_OE_N,    //	SRAM Output Enable
);

/////////////////////////////////////////
// INPUT/OUTPUT DEFINITION GOES HERE
////////////////////////////////////
//
// Clock Input
input	[1:0]	CLOCK_27; // 27 MHz
input       CLOCK_50; // 50 MHz
// Push Button
input	[3:0]	KEY; //	Pushbutton[3:0]
// DPDT Switch
input	[9:0]	SW;	// Toggle Switch[9:0]
// 7-SEG Dispaly
output [6:0] HEX0; // Seven Segment Digit 0
output [6:0] HEX1; // Seven Segment Digit 1
output [6:0] HEX2; // Seven Segment Digit 2
output [6:0] HEX3; // Seven Segment Digit 3
// LED
output [7:0] LEDG; // LED Green[7:0]
output [9:0] LEDR; // LED Red[9:0]
// VGA
output        VGA_HS; // VGA H_SYNC
output        VGA_VS; // VGA V_SYNC
output [3:0]  VGA_R;  // VGA Red[3:0]
output [3:0]  VGA_G;  // VGA Green[3:0]
output [3:0]  VGA_B;  // VGA Blue[3:0]
// SRAM Interface
inout	 [15:0] SRAM_DQ; // SRAM Data bus 16 Bits
output [17:0] SRAM_ADDR; // SRAM Address bus 18 Bits
output        SRAM_UB_N; // SRAM High-byte Data Mask 
output        SRAM_LB_N; // SRAM Low-byte Data Mask 
output        SRAM_WE_N; // SRAM Write Enable
output        SRAM_CE_N; // SRAM Chip Enable
output        SRAM_OE_N; // SRAM Output Enable

/////////////////////////////////////////
// TESTBENCH SIGNAL DECLARATION GOES HERE
/////////////////////////////////////////
//
reg test_clock;
initial begin
  test_clock = 1;
  #10000 $finish;
end

always begin 
  #20 test_clock = ~test_clock;
end

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//
wire pll_c0;
wire pll_locked;

wire LOCK_FD;
wire [`PC_WIDTH-1:0] PC_FD;
wire [`IR_WIDTH-1:0] IR_FD;

wire [`PC_WIDTH-1:0] BranchPC_FM;
wire BranchAddrSelect_FM;
wire DepStallSignal_FD;
wire BranchStallSignal_FD;
wire FetchStall_FD;

wire WritebackEnable_WD;
wire [3:0] WriteBackRegIdx_WD;
wire [`REG_WIDTH-1:0] WritebackData_WD;

wire LOCK_DE;
wire [`PC_WIDTH-1:0] PC_DE;
wire [`OPCODE_WIDTH-1:0] Opcode_DE;
wire [`REG_WIDTH-1:0] Src1Value_DE;
wire [`REG_WIDTH-1:0] Src2Value_DE;
wire [`VREG_WIDTH-1:0] VRegValue_DE;
wire [3:0] DestRegIdx_DE;
wire [`REG_WIDTH-1:0] DestValue_DE;
wire [`REG_WIDTH-1:0] Imm_DE;
wire FetchStall_DE;
wire DepStall_DE;

wire LOCK_EM;
wire [`REG_WIDTH-1:0] ALUOut_EM;
wire [`VREG_WIDTH-1:0] VALUOut_EM;
wire [`OPCODE_WIDTH-1:0] Opcode_EM;
wire [3:0] DestRegIdx_EM;
wire [`REG_WIDTH-1:0] DestValue_EM;
wire FetchStall_EM;
wire DepStall_EM;

wire LOCK_MW;
wire [`REG_WIDTH-1:0] ALUOut_MW;
wire [`VREG_WIDTH-1:0] VALUOut_MW;
wire [`OPCODE_WIDTH-1:0] Opcode_MW;
wire [`REG_WIDTH-1:0] MemOut_MW;
wire [3:0] DestRegIdx_MW;
wire FetchStall_MW;
wire DepStall_MW;

wire LOCK_WV;


wire LOCK_VR;

/////////////////////////////////////////
// PLL MODULE GOES HERE 
/////////////////////////////////////////
//
pll pll0 (
  .inclk0 (CLOCK_27[0]),
  .c0     (pll_c0),
  .locked (pll_locked)
);

/////////////////////////////////////////
// CPU PIPELINE MODULES GO HERE 
/////////////////////////////////////////
//
Fetch Fetch0 (
  .I_CLOCK(pll_c0),
  .I_LOCK(pll_locked),
  .I_BranchPC(BranchPC_FM),
  .I_BranchAddrSelect(BranchAddrSelect_FM),
  .I_BranchStallSignal(BranchStallSignal_FD),
  .I_DepStallSignal(DepStallSignal_FD),
  .O_LOCK(LOCK_FD),
  .O_FetchStall(FetchStall_FD),
  .O_PC(PC_FD),
  .O_IR(IR_FD)
);

Decode Decode0 (
  .I_CLOCK(pll_c0),
  .I_LOCK(LOCK_FD),
  .I_FetchStall(FetchStall_FD),
  .I_PC(PC_FD),
  .I_IR(IR_FD),
  .I_WriteBackEnable(WritebackEnable_WD),
  .I_WriteBackRegIdx(WriteBackRegIdx_WD),
  .I_WriteBackData(WritebackData_WD),
  .O_DepStallSignal(DepStallSignal_FD),
  .O_BranchStallSignal(BranchStallSignal_FD),
  .O_LOCK(LOCK_DE),
  .O_FetchStall(FetchStall_DE),
  .O_PC(PC_DE),
  .O_Opcode(Opcode_DE),
  .O_DepStall(DepStall_DE),
  .O_Src1Value(Src1Value_DE),
  .O_Src2Value(Src2Value_DE),
  .O_DestRegIdx(DestRegIdx_DE),
  .O_DestValue(DestValue_DE),
  .O_VDestValue(VRegValue_DE),
  .O_Imm(Imm_DE)
);

Execute Execute0 (
  .I_CLOCK(pll_c0),
  .I_LOCK(LOCK_DE),
  .I_FetchStall(FetchStall_DE),
  .I_PC(PC_DE),
  .I_Opcode(Opcode_DE),
  .I_Src1Value(Src1Value_DE),
  .I_Src2Value(Src2Value_DE),
  .I_DestRegIdx(DestRegIdx_DE),
  .I_DestValue(DestValue_DE),
  .I_VDestValue(VRegValue_DE),
  .I_Imm(Imm_DE),
  .I_DepStall(DepStall_DE),
  .O_LOCK(LOCK_EM),
  .O_FetchStall(FetchStall_EM),
  .O_ALUOut(ALUOut_EM),
  .O_VALUOut(VALUOut_EM),
  .O_Opcode(Opcode_EM),
  .O_DestRegIdx(DestRegIdx_EM),
  .O_DestValue(DestValue_EM),
  .O_DepStall(DepStall_EM)
);

Memory Memory0 (
  .I_CLOCK(pll_c0),
  .I_LOCK(LOCK_EM),
  .I_FetchStall(FetchStall_EM),
  .I_ALUOut(ALUOut_EM),
  .I_VALUOut(VALUOut_EM),
  .I_Opcode(Opcode_EM),
  .I_DestRegIdx(DestRegIdx_EM),
  .I_DestValue(DestValue_EM),
  .I_DepStall(DepStall_EM),
  .O_BranchPC(BranchPC_FM),
  .O_BranchAddrSelect(BranchAddrSelect_FM),
  .O_LOCK(LOCK_MW),
  .O_FetchStall(FetchStall_MW),
  .O_ALUOut(ALUOut_MW),
  .O_VALUOut(VALUOut_MW),
  .O_Opcode(Opcode_MW),
  .O_MemOut(MemOut_MW),
  .O_DestRegIdx(DestRegIdx_MW),
  .O_DepStall(DepStall_MW),
  .O_LEDR(LEDR),
  .O_LEDG(LEDG),
  .O_HEX0(HEX0),
  .O_HEX1(HEX1),
  .O_HEX2(HEX2),
  .O_HEX3(HEX3)
);

Writeback Writeback0 (
  .I_CLOCK(pll_c0),
  .I_LOCK(LOCK_MW),
  .I_FetchStall(FetchStall_MW),
  .I_ALUOut(ALUOut_MW),
  .I_Opcode(Opcode_MW),
  .I_MemOut(MemOut_MW),
  .I_DestRegIdx(DestRegIdx_MW),
  .I_DepStall(DepStall_MW),
  .O_LOCK(LOCK_WV),
  .O_WriteBackEnable(WritebackEnable_WD),
  .O_WriteBackRegIdx(WriteBackRegIdx_WD),
  .O_WriteBackData(WritebackData_WD)
);

Vertex Vertex0 (
	.I_CLOCK(pll_c0),
	.I_LOCK(LOCK_WV),
	.O_LOCK(LOCK_VR)
);

Rasterizer Rasterizer0 (
);
/////////////////////////////////////////
// TODO
// Rasterisation stage should be implemented here between writeback and gpu stages. 
// 1. Output interface of writeback stage should be extended.
// 2. Input interface of gpu stage also should be extended.
// 
// ** You don't have to modify VgaController, PixelGen and MultiSram(framebuffer) modules.
//
// ## Note
// 1. As an example code in the gpu module, you should update the output latch
// (O_GPU_DATA) of gpu module when I_VIDEO_ON is not asserted.
// 2. When I_VIDEO_ON is asserted, values stored in the framebuffer are
// displayed on the screen.
// /////////////////////////////////////////

/////////////////////////////////////////
// GPU PIPELINE MODULES GO HERE 
/////////////////////////////////////////
//
// VGA Connector Wires
wire [17:0]	mVGA_ADDR;
wire [15:0]	mVGA_DATA;
wire [9:0]  mVGA_X;
wire [9:0]  mVGA_Y;
wire [3:0]  mVGA_R;
wire [3:0]  mVGA_G;
wire [3:0]  mVGA_B;

// GPU Connector Wires
wire        mGPU_READ;
wire        mGPU_WRITE;
wire [17:0]	mGPU_ADDR;
wire [15:0]	mGPU_WRITE_DATA;
wire [15:0]	mGPU_READ_DATA;

VgaController VgaController0 (
  // Control Signal
  .I_CLK          (pll_c0),
  .I_RST_N        (KEY[0]),
  // Host Side				
  .I_RED          (mVGA_R),
  .I_GREEN        (mVGA_G),
  .I_BLUE         (mVGA_B),
  .O_COORD_X      (mVGA_X),
  .O_COORD_Y      (mVGA_Y),
  // VGA Side
  .O_VGA_R        (VGA_R),
  .O_VGA_G        (VGA_G),
  .O_VGA_B        (VGA_B),
  .O_VGA_H_SYNC   (VGA_HS),
  .O_VGA_V_SYNC   (VGA_VS)
);

Gpu Gpu0 (
  .I_CLK          (pll_c0),
  .I_RST_N        (KEY[0]),
  .I_VIDEO_ON     (VIDEO_ON),
  // GPU-SRAM interface
  .I_GPU_DATA     (mGPU_READ_DATA),
  .O_GPU_DATA     (mGPU_WRITE_DATA),
  .O_GPU_ADDR     (mGPU_ADDR),
  .O_GPU_READ     (mGPU_READ),
  .O_GPU_WRITE    (mGPU_WRITE)  
);

PixelGen PixelGen0 (
  // Control Signal
  .I_CLK          (pll_c0),
  .I_RST_N        (KEY[0]),
  // 
  .I_DATA         (mVGA_DATA),
  .I_COORD_X      (mVGA_X),
  .I_COORD_Y      (mVGA_Y),
  // SRAM Address Data
  .O_VIDEO_ON     (VIDEO_ON),
  .O_NEXT_ADDR    (mVGA_ADDR),
  .O_RED          (mVGA_R),
  .O_GREEN        (mVGA_G),
  .O_BLUE         (mVGA_B)
);

MultiSram MultiSram0 (	
  // VGA Side
  .I_VGA_READ     (VIDEO_ON),
  .I_VGA_ADDR     (mVGA_ADDR),
  .O_VGA_DATA     (mVGA_DATA),
  // GPU Side
  .I_GPU_ADDR     (mGPU_ADDR),
  .I_GPU_DATA     (mGPU_WRITE_DATA),
  .I_GPU_READ     (mGPU_READ), 
  .I_GPU_WRITE    (mGPU_WRITE),
  .O_GPU_DATA     (mGPU_READ_DATA),
  // SRAM
  .I_SRAM_DQ      (SRAM_DQ),
  .O_SRAM_ADDR    (SRAM_ADDR),
  .O_SRAM_UB_N    (SRAM_UB_N),
  .O_SRAM_LB_N    (SRAM_LB_N),
  .O_SRAM_WE_N    (SRAM_WE_N),
  .O_SRAM_CE_N    (SRAM_CE_N),
  .O_SRAM_OE_N    (SRAM_OE_N)
);

endmodule // module lg_highlevel
