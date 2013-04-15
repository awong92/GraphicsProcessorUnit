`include "global_def.h"

module Vertex(
    I_CLOCK,
    I_LOCK,
    I_VRegIn,
    I_Opcode,
    O_VOut,
    O_ColorOut,
    O_LOCK
);

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
//
// Inputs from the fetch stage
input I_CLOCK;
input I_LOCK;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input [`VREG_WIDTH-1:0] I_VRegIn;

output O_LOCK;
output [`VREG_WIDTH-1:0] O_ColorOut;
output  reg [`VREG_WIDTH-1:0] O_VOut;

reg [1:0] i;
reg [1:0] j;
reg [1:0] k;

reg is_setvertex; 
reg is_startprimitive; 
reg is_endprimitive; 
reg is_draw; 
reg is_flush;

reg result[0:`REG_WIDTH]; 

reg [`DATA_WIDTH:0] matrixTemp[0:`REG_WIDTH]; 
reg [`DATA_WIDTH:0] matrixBackup[0:`REG_WIDTH]; 

reg [`DATA_WIDTH:0] matrixCurrent[0:`REG_WIDTH]; 
reg [`VREG_WIDTH-1:0] ColorCurrent;

reg [`DATA_WIDTH:0] matrixPast[0:`REG_WIDTH]; 
reg [`VREG_WIDTH-1:0] ColorPast;

reg [`DATA_WIDTH:0] vertex [0:2];

reg angle;

reg [`DATA_WIDTH:0] x;
reg [`DATA_WIDTH:0] y;
reg [`DATA_WIDTH:0] xres;
reg [`DATA_WIDTH:0] yres;

assign O_LOCK = I_LOCK;

initial
begin
  is_startprimitive = 0; 
  xres = 0;
  yres = 0;
  zres = 0;
end 

always @(negedge I_CLOCK)
begin
  if (I_LOCK == 1'b1)
  begin

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
             
             xres = xres + matrixCurrent[4*0+ 0] * x;
             xres = xres + matrixCurrent[0 + 1] * y;
             xres = xres + matrixCurrent[0 + 3] * 1;
             O_VOut[31:16] = xres;

             y_result = 0;
             yres = yres + matrixCurrent[4*1 + 0] * x;
             yres = yres + matrixCurrent[4*1 + 1] * y;
             yres = yres + matrixCurrent[4*1 + 3] * 1;
             O_VOut[47:32] = yres;

             O_VOut[15:0] = I_VRegIn[15:0];
             O_VOut[63:48] = I_VRegIn[63:48];

            
            end

            if (I_Opcode==`OP_SETCOLOR) begin
                O_ColorOut <= I_VRegIn;
                ColorCurrent <= I_VRegIn;
            end

            if (I_Opcode==`OP_ROTATE) begin
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

                if(I_VRegIn[63] == 1) begin
                    angle = (-1) * angle;
                end

                matrixTemp[4*0 + 0] = cos(angle*3.14159/180);
                matrixTemp[4*1 + 0] = (-1) * sin(angle*3.14159/180);
                matrixTemp[4*0 + 1] = sin(angle*3.14159/180);
                matrixTemp[4*1 + 1] = cos(angle*3.14159/180);

                //Matrix Multiply
                for( i = 0; i < 4; i=i+1)begin
                    for( j = 0; j < 4; j=j+1)begin
                        result = 0;         //WTF
                        for( k = 0; k < 4; k=k+1) begin
                            result = result + (matrixBackup[4*i+k] * matrixTemp[4*k+j]);
                        end
                        matrixCurrent[4*i+j] = result;
                    end
                end
            end


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
                            matrixTemp[4*j+k] = 1;
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
                            result = result + (matrixBackup[4*i+k] * matrixTemp[4*k+j]);
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
                            matrixTemp[4*j+k] = 1;
                        end
                    end
                end

                matrixTemp[0] = I_VRegIn[31:16];
                matrixTemp[4*1+1] = I_VRegIn[47:32];

                //Matrix Multiply
                for(i = 0; i < 4; i=i+1)begin
                    for(j = 0; j < 4; j=j+1)begin
                        result = 0;         //WTF
                        for(k = 0; k < 4; k=k+1) begin
                            result = result + (matrixBackup[4*i+k] * matrixTemp[4*k+j]);
                        end
                        matrixCurrent[4*i+j] = result;
                    end
                end
            end


            if (I_Opcode==`OP_PUSHMATRIX) begin
                matrixPast = matrixCurrent;
                colorPast = colorCurrent;
            end

            if (I_Opcode==`OP_LOADIDENTITY) begin
                for(j = 0; j < 4; j = j+1)begin
                    for(k = 0; k < 4; k=k+1)begin
                        matrixCurrent[4*j+k] = 0;
                        if(j == k) begin
                            matrixCurrent[4*j+k] = 1;
                        end
                    end
                end
                
                colorCurrent = 0;
            end


            if (I_Opcode==`OP_POPMATRIX) begin
                matrixCurrent = matrixPast;
                colorCurret = colorPast;
            end

  end // if (I_LOCK == 1'b1)
end // always @(negedge I_CLOCK)


endmodule // module Decode