`include "global_def.h"

module Vertex(
    I_CLOCK,
    I_LOCK,
    I_VRegIn,
    I_Opcode,
	 I_FRAMESTALL,
    O_VOut,
    O_ColorOut,
	 O_Opcode,
    O_LOCK
);

////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
//
// Inputs from the fetch stage
input I_CLOCK;
input I_LOCK;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input [`VREG_WIDTH-1:0] I_VRegIn;
input I_FRAMESTALL;

output O_LOCK;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg [`VREG_WIDTH-1:0] O_ColorOut;
output  reg [`VREG_WIDTH-1:0] O_VOut;

reg [4:0] i;
reg [3:0] j;
reg [3:0] k;

reg is_setvertex; 
reg is_startprimitive; 
reg is_endprimitive; 
reg is_draw; 
reg is_flush;


reg [`DATA_WIDTH-1:0] matrixTemp[0:`REG_WIDTH-1]; 
reg [`DATA_WIDTH-1:0] matrixBackup[0:`REG_WIDTH-1]; 

reg [`DATA_WIDTH-1:0] matrixCurrent[0:`REG_WIDTH-1]; 
reg [`VREG_WIDTH-1:0] ColorCurrent;

reg [`DATA_WIDTH-1:0] matrixPast[0:`REG_WIDTH-1]; 
reg [`VREG_WIDTH-1:0] ColorPast;

reg [`DATA_WIDTH-1:0] vertex [0:2];

reg [`DATA_WIDTH-1:0]angle;

reg [`DATA_WIDTH-1:0] x;
reg [`DATA_WIDTH-1:0] y;
reg [`DATA_WIDTH-1:0] xres;
reg [`DATA_WIDTH-1:0] yres;
reg [`DATA_WIDTH-1:0] result;

reg[15:0] cosTable[0:359];
reg[15:0] sinTable[0:359];


assign O_LOCK = I_LOCK;

initial
begin
  is_startprimitive = 0; 
  xres = 0;
  yres = 0;
  result = 0;
 matrixCurrent[0] = 1<<7;
 matrixCurrent[1] = 0;
 matrixCurrent[2] = 0;
 matrixCurrent[3] = 0;
 matrixCurrent[4] = 0;
 matrixCurrent[5] = 1<<7;
 matrixCurrent[6] = 0;
 matrixCurrent[7] = 0;
 matrixCurrent[8] = 0;
 matrixCurrent[9] = 0;
 matrixCurrent[10] = 1<<7;
 matrixCurrent[11] = 0;
 matrixCurrent[12] = 0;
 matrixCurrent[13] = 0;
 matrixCurrent[14] = 0;
 matrixCurrent[15] = 1<<7;
 
 matrixPast[0] = 1<<7;
 matrixPast[1] = 0;
 matrixPast[2] = 0;
 matrixPast[3] = 0;
 matrixPast[4] = 0;
 matrixPast[5] = 1<<7;
 matrixPast[6] = 0;
 matrixPast[7] = 0;
 matrixPast[8] = 0;
 matrixPast[9] = 0;
 matrixPast[10] = 1<<7;
 matrixPast[11] = 0;
 matrixPast[12] = 0;
 matrixPast[13] = 0;
 matrixPast[14] = 0;
 matrixPast[15] = 1<<7;
 
 matrixTemp[0] = 1<<7;
 matrixTemp[1] = 0;
 matrixTemp[2] = 0;
 matrixTemp[3] = 0;
 matrixTemp[4] = 0;
 matrixTemp[5] = 1<<7;
 matrixTemp[6] = 0;
 matrixTemp[7] = 0;
 matrixTemp[8] = 0;
 matrixTemp[9] = 0;
 matrixTemp[10] = 1<<7;
 matrixTemp[11] = 0;
 matrixTemp[12] = 0;
 matrixTemp[13] = 0;
 matrixTemp[14] = 0;
 matrixTemp[15] = 1<<7;
 
  matrixPast[0] = 1<<7;
 matrixBackup[1] = 0;
 matrixBackup[2] = 0;
 matrixBackup[3] = 0;
 matrixBackup[4] = 0;
 matrixBackup[5] = 1<<7;
 matrixBackup[6] = 0;
 matrixBackup[7] = 0;
 matrixBackup[8] = 0;
 matrixBackup[9] = 0;
 matrixBackup[10] = 1<<7;
 matrixBackup[11] = 0;
 matrixBackup[12] = 0;
 matrixBackup[13] = 0;
 matrixBackup[14] = 0;
 matrixBackup[15] = 1<<7;
 
 ColorPast <= 0;
  $readmemh("cosine.hex", cosTable);
  $readmemh("sine.hex", sinTable);
end 

always @(negedge I_CLOCK)
begin
  if (I_LOCK == 1'b1 && I_FRAMESTALL == 0)
  begin
				O_Opcode<=I_Opcode;
				
            if (I_Opcode==`OP_BEGINPRIMITIVE) begin
              is_startprimitive = 1; 
            end

            if (I_Opcode==`OP_ENDPRIMITIVE) begin
              is_startprimitive = 0; 
            end
            

            if (I_Opcode==`OP_SETVERTEX && is_startprimitive) begin
             x = I_VRegIn[31:16];
             y = I_VRegIn[47:32];

             xres = 0;
             yres = 0;
             
             xres[15:7] = xres[15:7] + matrixCurrent[0][15:7] * I_VRegIn[31:23];
             xres[6:0] = xres[6:0] + matrixCurrent[0][6:0] * I_VRegIn[22:16];
             xres[15:7] = xres[15:7] + matrixCurrent[1][15:7] * I_VRegIn[31:23];
             xres[6:0] = xres[6:0] + matrixCurrent[1][6:0] * I_VRegIn[22:16];
             xres = xres + matrixCurrent[3];
             O_VOut[31:16] = xres;

             yres[15:7] = yres[15:7] + matrixCurrent[4][15:7] * I_VRegIn[47:39];
             yres[6:0] = yres[6:0] + matrixCurrent[4][6:0] * I_VRegIn[38:32];
             yres[15:7] = yres[15:7] + matrixCurrent[5][15:7] * I_VRegIn[47:39];
				 yres[6:0] = yres[6:0] + matrixCurrent[5][6:0] * I_VRegIn[38:32];
             yres = yres + matrixCurrent[7];
             O_VOut[47:32] = yres;

             O_VOut[15:0] = I_VRegIn[15:0];
             O_VOut[63:48] = I_VRegIn[63:48];

            
            end

            if (I_Opcode==`OP_SETCOLOR) begin
                O_ColorOut <= I_VRegIn;
                ColorCurrent <= I_VRegIn;
            end

  /**          if (I_Opcode==`OP_ROTATE) begin
                for( j = 0; j < 4; j=j+1) begin
                    for( k = 0; k < 4; k=k+1) begin
                        matrixBackup[4*j + k] = matrixCurrent[4*j+k];
                    end
                end

                for( j = 0; j < 4; j=j+1) begin
                    for( k = 0; k < 4; k=k+1) begin
                        matrixTemp[4*j+k] = 0;
                        if(j == k)begin
                            matrixTemp[4*j+k] = 1;
                        end
                    end
                end
                
					 angle=I_VRegIn[15:0];
                if(I_VRegIn[63] == 1) begin
						  if (angle[15] == 1) begin
								angle[15] = 0;
						  end else begin
								angle[15] = 1;
						  end
                end

					 if (angle[15] == 1) begin
						angle = 360-angle[14:7];
					 end else begin
						angle = angle[14:7];							
					 end
					 angle = angle * 2;
					 angle = angle % 360; 
					 
					 matrixTemp[0] = cosTable[angle];
					 matrixTemp[1] = sinTable[angle];
					 matrixTemp[5] = cosTable[angle]; 
					 matrixTemp[4] = -1* sinTable[angle];
					 
					 /*if (I_VRegIn[15] == 1) begin
						matrixTemp[4*1 + 0][15] = 0;
					 end else begin
						matrixTemp[4*1 + 0][15] = 1;
					 end*/

                //Matrix Multiply
           /**     for( i = 0; i < 4; i=i+1)begin **/
     /**               for( j = 0; j < 4; j=j+1)begin
                        for( k = 0; k < 4; k=k+1) begin
                            result = result + (matrixBackup[4*i+k] * matrixTemp[4*k+j]);
                        end
                        matrixCurrent[4*i+j] = result;
                    end
                end
            end

*/
            if (I_Opcode==`OP_TRANSLATE) begin
                for(j = 0; j < 4; j=j+1) begin
                    for(k = 0; k < 4; k=k+1) begin
                        matrixBackup[4*j + k] = matrixCurrent[4*j+k];
                    end
                end

                for(j = 0; j < 4; j=j+1) begin
                    for(k = 0; k < 4; k=k+1) begin
                        matrixTemp[4*j+k] = 0;
                        if(j == k)begin
                            matrixTemp[4*j+k] = 1<<7;
                        end
                    end
                end

                matrixTemp[4*0 + 3] = I_VRegIn[31:16];
                matrixTemp[4*1 + 3] = I_VRegIn[47:32];

                //Matrix Multiply
                for(i = 0; i < 4; i=i+1)begin
                    for(j = 0; j < 4; j=j+1)begin
                        result = 0;         //WTF
                        for(k = 0; k < 4; k=k+1) begin
                            result[6:0] = result[6:0] + (matrixBackup[4*i+k][6:0] * matrixTemp[4*k+j][6:0]);
                            result[15:7] = result[15:7] + (matrixBackup[4*i+k][15:7] * matrixTemp[4*k+j][15:7]);
                        end
                        matrixCurrent[4*i+j] = result;
                    end
                end
            end

           
            if (I_Opcode==`OP_SCALE) begin
                for(j = 0; j < 4; j=j+1) begin
                    for(k = 0; k < 4; k=k+1) begin
                        matrixBackup[4*j + k] = matrixCurrent[4*j+k];
                    end
                end	

                for(j = 0; j < 4; j=j+1) begin
                    for(k = 0; k < 4; k=k+1) begin
                        matrixTemp[4*j+k] = 0;
                        if(j == k)begin
                            matrixTemp[4*j+k] = 1<<7;
                        end
                    end
                end

                matrixTemp[0] = I_VRegIn[31:16];
                matrixTemp[5] = I_VRegIn[47:32];

                //Matrix Multiply
                for(i = 0; i < 4; i=i+1)begin
                    for(j = 0; j < 4; j=j+1)begin
                        result = 0;         //WTF
                        for(k = 0; k < 4; k=k+1) begin
                            result[6:0] = result[6:0] + (matrixBackup[4*i+k][6:0] * matrixTemp[4*k+j][6:0]);
                            result[15:7] = result[15:7] + (matrixBackup[4*i+k][15:7] * matrixTemp[4*k+j][15:7]);
                        end
                        matrixCurrent[4*i+j] = result;
                    end
                end
            end 


            if (I_Opcode==`OP_PUSHMATRIX) begin
					for (i=0; i< `REG_WIDTH; i = i + 1)begin
						matrixPast[i] = matrixCurrent[i];
					 end
                ColorPast <= ColorCurrent;
            end

            if (I_Opcode==`OP_LOADIDENTITY) begin
                matrixCurrent[0] = 1;
					 matrixCurrent[1] = 0;
					 matrixCurrent[2] = 0;
					 matrixCurrent[3] = 0;
					 matrixCurrent[4] = 0;
					 matrixCurrent[5] = 1;
					 matrixCurrent[6] = 0;
					 matrixCurrent[7] = 0;
					 matrixCurrent[8] = 0;
					 matrixCurrent[9] = 0;
					 matrixCurrent[10] = 1;
					 matrixCurrent[11] = 0;
					 matrixCurrent[12] = 0;
					 matrixCurrent[13] = 0;
					 matrixCurrent[14] = 0;
					 matrixCurrent[15] = 1;
                ColorCurrent <= 0;
            end


            if (I_Opcode==`OP_POPMATRIX) begin
				
					for (i=0; i< `REG_WIDTH; i = i + 1)begin
						matrixCurrent[i] = matrixPast[i];
					 end
                ColorCurrent <= ColorPast;
            end

  end // if (I_LOCK == 1'b1)
end // always @(negedge I_CLOCK)

endmodule // module Decode