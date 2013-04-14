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
output [`VREG_WIDTH-1:0] O_VOut;

reg is_setvertex; 
reg is_startprimitive; 
reg is_endprimitive; 
reg is_draw; 
reg is_flush;

reg [`DATA_WIDTH:0] matrixTemp[0:`REG_WIDTH]; 
reg [`DATA_WIDTH:0] matrixBackup[0:`REG_WIDTH]; 

reg [`DATA_WIDTH:0] matrixCurrent[0:`REG_WIDTH]; 


reg [`DATA_WIDTH:0] matrixPast[0:`REG_WIDTH]; 
reg rPast;
reg gPast;
reg bPast;

reg [`DATA_WIDTH:0] vertex [0:2];

reg angle;

initial
begin
  is_startprimitive = 0; 
end 

always @(negedge I_CLOCK)
begin
  if (I_LOCK == 1'b1)
  begin

			if (OPCODE==`OP_BEGINPRIMITIVE) begin
			  is_startprimitive = 1; 
			end

			if (OPCODE==`OP_ENDPRIMITIVE) begin
			  is_startprimitive = 0; 
			end
			

			if (OPCODE==`OP_SETVERTEX && is_startprimitive) begin
				xTemp = inV1;
				yTemp = inV2;
				zTemp = inV3;
				//pop matrix and multipy
				x =;
				y =;
				z =;
			end

			if (OPCODE==`OP_COLOR) begin
				r = inV1;
				g = inV2;
				b = inV3;
			end

			if (OPCODE==`OP_ROTATE) begin
				for(int j = 0; j < 4; j=j+1) begin
					for(int k = 0; k < 4; k=k+1) begin
						matrixBackup[4*j + k] = matrixCurrent[4*j+k];
					end
				end

				for(int j = 0; j < 4; j=j+1) begin
					for(int k = 0; k < 4; k=k+1) begin
						matrixTemp[4*j+k] = 0;
						if(j == k)begin
							matrixTemp[4*j+k] = 1;
						end
					end
				end

				if(inV3 < 0){
					angle = (-1) * angle;
				}

				matrixTemp[4*0 + 0] = cos(angle*3.14159/180);
				matrixTemp[4*1 + 0] = (-1) * sin(angle*3.14159/180);
				matrixTemp[4*0 + 1] = sin(angle*3.14159/180);
				matrixTemp[4*1 + 1] = cos(angle*3.14159/180);

				//Matrix Multiply
				for(int i = 0; i < 4; i=i+1)begin
					for(int j = 0; j < 4; j=j+1)begin
						float result = 0;			//WTF
						for(int k = 0; k < 4; k=k+1) begin
							result = result + (matrixBackup[4*i+k] * matrixTemp[4*k+j]);
						end
						matrixCurrent[4*i+j] = result;
					end
				end
			end


			if (OPCODE==`OP_TRANSLATE) begin
				for(int j = 0; j < 4; j=j+1) begin
					for(int k = 0; k < 4; k=k+1) begin
						matrixBackup[4*j + k] = matrixCurrent[4*j+k];
					end
				end

				for(int j = 0; j < 4; j=j+1) begin
					for(int k = 0; k < 4; k=k+1) begin
						matrixTemp[4*j+k] = 0;
						if(j == k)begin
							matrixTemp[4*j+k] = 1;
						end
					end
				end

				matrixTemp[4*0 + 3] = inV1;
				matrixTemp[4*1 + 3] = inV2;

				//Matrix Multiply
				for(int i = 0; i < 4; i=i+1)begin
					for(int j = 0; j < 4; j=j+1)begin
						float result = 0;			//WTF
						for(int k = 0; k < 4; k=k+1) begin
							result = result + (matrixBackup[4*i+k] * matrixTemp[4*k+j]);
						end
						matrixCurrent[4*i+j] = result;
					end
				end
			end

			
			if (OPCODE==`OP_SCALE) begin
				for(int j = 0; j < 4; j=j+1) begin
					for(int k = 0; k < 4; k=k+1) begin
						matrixBackup[4*j + k] = matrixCurrent[4*j+k];
					end
				end

				for(int j = 0; j < 4; j=j+1) begin
					for(int k = 0; k < 4; k=k+1) begin
						matrixTemp[4*j+k] = 0;
						if(j == k)begin
							matrixTemp[4*j+k] = 1;
						end
					end
				end

				matrixTemp[0] = inV1;
				matrixTemp[4*1+1] = inV2;

				//Matrix Multiply
				for(int i = 0; i < 4; i=i+1)begin
					for(int j = 0; j < 4; j=j+1)begin
						float result = 0;			//WTF
						for(int k = 0; k < 4; k=k+1) begin
							result = result + (matrixBackup[4*i+k] * matrixTemp[4*k+j]);
						end
						matrixCurrent[4*i+j] = result;
					end
				end
			end


			if (OPCODE==`OP_PUSHMATRIX) begin
				matrixPast = matrixCurrent;
				rPast = r;
				gPast = g;
				bPast = b;
			end

			if (OPCODE==`OP_LOADIDENTITY) begin
				for(int j = 0; j < 4; j = j+1)begin
					for(int k = 0; k < 4; k=k+1)begin
						matrixCurrent[4*j+k] = 0;
						if(j == k){
							matrixCurrent[4*j+k] = 1;
						}
					end
				end
				
				r = 0;
				g = 0;
				b = 0;
			end


			if (OPCODE==`OP_POPMATRIX) begin
				matrixCurrent = matrixPast;
				r = rPast;
				g = gPast;
				b = bPast;
				}
			end

  end // if (I_LOCK == 1'b1)
end // always @(negedge I_CLOCK)


endmodule // module Decode
