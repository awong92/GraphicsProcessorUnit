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
reg [`DATA_WIDTH+6:0] xres;
reg [`DATA_WIDTH+6:0] tempVal[0:2];
reg [`DATA_WIDTH+6:0] yres;
reg [`DATA_WIDTH+6:0] result;

//reg[15:0] cosTable[0:359];
//reg[15:0] sinTable[0:359];


assign O_LOCK = I_LOCK;

initial
begin
  is_startprimitive = 0; 
  xres = 0;
  yres = 0;
  tempVal[0] = 0;
  tempVal[1] = 0;
  tempVal[2] = 0;
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
 
 matrixBackup[0] = 1<<7;
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
 
 angle = 0;
 
 ColorPast <= 0;
 // $readmemh("cosine.hex", cosTable);
 // $readmemh("sine.hex", sinTable);
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
             tempVal[0] = ((matrixCurrent[0] * I_VRegIn[31:16])>>7);
				 if(matrixCurrent[0][15:7] == 9'b100000000 || matrixCurrent[0][15:7] == 9'b000000000)
				 begin
				   if(x == 0)
					begin
					 tempVal[0] = 0;
					end
					else if(matrixCurrent[0][6:0] > 0)
					begin
						tempVal[0] = matrixCurrent[0];
						if(I_VRegIn[31] == 1'b1)
						begin						
							tempVal[0][15] = !tempVal[0][15];
						end
					end
				 end

				 tempVal[1] = ((matrixCurrent[1] * I_VRegIn[47:32])>>7);
				 if(matrixCurrent[1][15:7] == 9'b100000000 || matrixCurrent[1][15:7] == 9'b000000000)
				 begin
				   if(y == 0)
					begin
					 tempVal[1] = 0;
					end
					else if(matrixCurrent[1][6:0] > 0)
					begin
						tempVal[1] = matrixCurrent[1];
						if(I_VRegIn[47] == 1'b1)
						begin						
							tempVal[1][15] = !tempVal[1][15];
						end
					end
				 end
				 

				 
				 if(tempVal[0][15:7] == 9'b100000000 && tempVal[1][15:7]  ==  9'b100000000)
				 begin
					tempVal[2] = tempVal[1] + tempVal[0];
					tempVal[2][15] = 1'b1;
				 end
				 else if((tempVal[0][15:7] == 1'b0 && tempVal[1][15:7] ==  9'b100000000) || (tempVal[0][15:7] ==  9'b100000000 && tempVal[1][15:7] == 1'b0))
				 begin
				   if(tempVal[0][14:0] >= tempVal[1][14:0])
					begin
					  tempVal[2] = tempVal[0] - tempVal[1];
					  tempVal[2][15] = tempVal[0][15];
					end
					else
					begin
					  tempVal[2] = tempVal[1] - tempVal[0];
					  tempVal[2][15] = tempVal[1][15];	
					end
				 end
				 else
				 begin
					tempVal[2] = tempVal[1] + tempVal[0];
				 end
             xres = xres + tempVal[2];
             xres = xres + matrixCurrent[3];
             O_VOut[31:16] = xres;

				 tempVal[0] = ((matrixCurrent[4] * I_VRegIn[31:16])>>7);
				 if(matrixCurrent[4][15:7] == 9'b100000000 || matrixCurrent[4][15:7] == 9'b000000000)
				 begin
				   if(x == 0)
					begin
					 tempVal[0] = 0;
					end
					else if(matrixCurrent[4][6:0] > 0)
					begin
						tempVal[0] = matrixCurrent[4];
						if(I_VRegIn[31] == 1'b1)
						begin						
							tempVal[0][15] = !tempVal[0][15];
						end
					end
				 end

				 tempVal[1] = ((matrixCurrent[5] * I_VRegIn[47:32])>>7);
				 if(matrixCurrent[5][15:7] == 9'b100000000 || matrixCurrent[5][15:7] == 9'b000000000)
				 begin
				  if(y == 0)
					begin
					 tempVal[1] = 0;
					end
					else if(matrixCurrent[5][6:0] > 0)
					begin
						tempVal[1] = matrixCurrent[5];
						if(I_VRegIn[47] == 1'b1)
						begin						
							tempVal[1][15] = !tempVal[1][15];
						end
					end
				 end
				 
				 
				 if(tempVal[0][15:7] == 9'b100000000 && tempVal[1][15:7]  ==  9'b100000000)
				 begin
					tempVal[2] = tempVal[1] + tempVal[0];
					tempVal[2][15] = 1'b1;
				 end
				 else if((tempVal[0][15:7] == 1'b0 && tempVal[1][15:7] ==  9'b100000000) || (tempVal[0][15:7] ==  9'b100000000 && tempVal[1][15:7] == 1'b0))
				 begin
				   if(tempVal[0][14:0] >= tempVal[1][14:0])
					begin
					  tempVal[2] = tempVal[0] - tempVal[1];
					  tempVal[2][15] = tempVal[0][15];
					end
					else
					begin
					  tempVal[2] = tempVal[1] - tempVal[0];
					  tempVal[2][15] = tempVal[1][15];	
					end
				 end
				 else
				 begin
					tempVal[2] = tempVal[1] + tempVal[0];
				 end

             yres = yres + tempVal[2];
             yres = yres + matrixCurrent[7];
             O_VOut[47:32] = yres;

             O_VOut[15:0] = I_VRegIn[15:0];
             O_VOut[63:48] = I_VRegIn[63:48];

            
            end

            if (I_Opcode==`OP_SETCOLOR) begin
                O_ColorOut <= I_VRegIn;
                ColorCurrent <= I_VRegIn;
            end

            if (I_Opcode==`OP_ROTATE) begin
                for (i=0; i< `REG_WIDTH; i = i + 1)begin
						matrixBackup[i] = matrixCurrent[i];
					 end

					
		
					 matrixTemp[2] = 0;
					 matrixTemp[3] = 0;
					 
					 
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
                
                angle = I_VRegIn[15:0]>>7;
                if(I_VRegIn[63] == 1)
					 begin
						angle = angle * (-1);
					 end
                if (angle[15] == 1) begin
                        angle = (-1) * angle;
                        angle = 360-angle;
                 end
					  /**
                 angle = angle * 2;
                 angle = angle % 360; **/
                 if(angle >= 0 && angle <= 29)
					  begin
						  matrixTemp[0] = 16'h0080;
						  matrixTemp[1] = 16'h0000;
						  matrixTemp[5] = 16'h0080; 
						  matrixTemp[4] = 16'h0000;
					  end
                 if(angle >= 30 && angle <= 59)
					  begin
						  matrixTemp[0] = 16'h0070;
						  matrixTemp[1] = 16'h0040;
						  matrixTemp[5] = 16'h0070; 
						  matrixTemp[4] = 16'h8040;
					  end
                 if(angle >= 60 && angle <= 89)
					  begin
						  matrixTemp[0] = 16'h0040;
						  matrixTemp[1] = 16'h0070;
						  matrixTemp[5] = 16'h0040; 
						  matrixTemp[4] = 16'h8070;
					  end
                 if(angle >= 90 && angle <= 119)
					  begin
						  matrixTemp[0] = 16'h0000;
						  matrixTemp[1] = 16'h0080;
						  matrixTemp[5] = 16'h0000; 
						  matrixTemp[4] = 16'hFF80;
					  end
                 if(angle >= 120 && angle <= 149)
					  begin
						  matrixTemp[0] = 16'h8040;
						  matrixTemp[1] = 16'h0070;
						  matrixTemp[5] = 16'h8040; 
						  matrixTemp[4] = 16'h8070;
					  end
                 if(angle >= 150 && angle <= 179)
					  begin
						  matrixTemp[0] = 16'h8070;
						  matrixTemp[1] = 16'h0040;
						  matrixTemp[5] = 16'h8070; 
						  matrixTemp[4] = 16'h8040;
					  end
                 if(angle >= 180 && angle <= 209)
					  begin
						  matrixTemp[0] = 16'hFF80;
						  matrixTemp[1] = 16'h0000;
						  matrixTemp[5] = 16'hFF80; 
						  matrixTemp[4] = 16'h0000;
					  end
                 if(angle >= 210 && angle <= 239)
					  begin
						  matrixTemp[0] = 16'h8070;
						  matrixTemp[1] = 16'h8040;
						  matrixTemp[5] = 16'h8070; 
						  matrixTemp[4] = 16'h0040;
					  end
                 if(angle >= 240 && angle <= 269)
					  begin
						  matrixTemp[0] = 16'h8040;
						  matrixTemp[1] = 16'h8070;
						  matrixTemp[5] = 16'h8040; 
						  matrixTemp[4] = 16'h0070;
					  end
                 if(angle >= 270 && angle <= 299)
					  begin
						  matrixTemp[0] = 16'h0000;
						  matrixTemp[1] = 16'h0080;
						  matrixTemp[5] = 16'h0000; 
						  matrixTemp[4] = 16'hFF80;
					  end
                 if(angle >= 300 && angle <= 329)
					  begin
						  matrixTemp[0] = 16'h0040;
						  matrixTemp[1] = 16'h8070;
						  matrixTemp[5] = 16'h0040; 
						  matrixTemp[4] = 16'h0070;
					  end
                 if(angle >= 330 && angle <= 359)
					  begin
						  matrixTemp[0] = 16'h0070;
						  matrixTemp[1] = 16'h8040;
						  matrixTemp[5] = 16'h0070; 
						  matrixTemp[4] = 16'h0040;
					  end	  
					  
             /**   //Matrix Multiply
                for( i = 0; i < 4; i=i+1)begin
							for( j = 0; j < 4; j=j+1)begin
								result = 0;         //WTF
                        for( k = 0; k < 4; k=k+1) begin
                            result = result + ((matrixBackup[4*i+k] * matrixTemp[4*k+j])>>7);
                        end
                        matrixCurrent[4*i+j] = result;
                    end
                end **/
					 
					 for (i=0; i< `REG_WIDTH; i = i + 1)begin
						matrixCurrent[i] = matrixTemp[i];
					 end

            end


            if (I_Opcode==`OP_TRANSLATE) begin
                for (i=0; i< `REG_WIDTH; i = i + 1)begin
						matrixBackup[i] = matrixCurrent[i];
					 end

					 matrixTemp[0] = 1<<7;
					 matrixTemp[1] = 0;
					 matrixTemp[2] = 0;
					 matrixTemp[3] = I_VRegIn[31:16];
					 matrixTemp[4] = 0;
					 matrixTemp[5] = 1<<7;
					 matrixTemp[6] = 0;
					 matrixTemp[7] = I_VRegIn[47:32];
					 matrixTemp[8] = 0;
					 matrixTemp[9] = 0;
					 matrixTemp[10] = 1<<7;
					 matrixTemp[11] = 0;
					 matrixTemp[12] = 0;
					 matrixTemp[13] = 0;
					 matrixTemp[14] = 0;
					 matrixTemp[15] = 1<<7;

                
                

                //Matrix Multiply
                for(i = 0; i < 4; i=i+1)begin
                    for(j = 0; j < 4; j=j+1)begin
                        result = 0;         //WTF
                        for(k = 0; k < 4; k=k+1) begin
                            result = result + ((matrixBackup[4*i+k] * matrixTemp[4*k+j])>>7);
                        end
                        matrixCurrent[4*i+j] = result[15:0];
                    end
                end
            end

           
            if (I_Opcode==`OP_SCALE) begin	
					 for (i=0; i< `REG_WIDTH; i = i + 1)begin
						matrixBackup[i] = matrixCurrent[i];
					 end

                     matrixTemp[0] = I_VRegIn[31:16];
							 matrixTemp[1] = 0;
							 matrixTemp[2] = 0;
							 matrixTemp[3] = 0;
							 matrixTemp[4] = 0;
							 matrixTemp[5] = I_VRegIn[47:32];
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

                
                

                //Matrix Multiply
                for(i = 0; i < 4; i=i+1)begin
                    for(j = 0; j < 4; j=j+1)begin
                        result = 0;         //WTF
                        for(k = 0; k < 4; k=k+1) begin
                            result = result + ((matrixBackup[4*i+k] * matrixTemp[4*k+j])>>7);
                        end
                        matrixCurrent[4*i+j] = result[15:0];
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