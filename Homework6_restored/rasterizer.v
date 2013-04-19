`include "global_def.h"

module Rasterizer(
    I_CLOCK,
    I_LOCK,
    I_Opcode,
    I_Vertex,
	 I_ColorIn,
	 O_ColorOut,
	 O_ADDROut,
    O_LOCK,
	 O_FRAMESTALL,
	 O_LEDR,
    O_LEDG,
    O_HEX0,
    O_HEX1,
    O_HEX2,
    O_HEX3
);
input I_CLOCK;
input I_LOCK;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input [`VREG_WIDTH-1:0] I_Vertex;
input [`VREG_WIDTH-1:0] I_ColorIn;

output O_LOCK;
output reg [17:0] O_ADDROut;
output reg [63:0] O_ColorOut;
output reg O_FRAMESTALL;
/*
* State machine variables dawg
*/
reg is_setvertex;
reg is_startprimitive;
reg is_endprimitive;
reg is_draw;

// Outputs for debugging
output [9:0] O_LEDR;
output [7:0] O_LEDG;
output [6:0] O_HEX0, O_HEX1, O_HEX2, O_HEX3;


reg [`VREG_WIDTH-1:0] vertices [0:8];
reg [3:0] currentVertex;
reg [8:0] currentState;
reg [3:0] currentTriangle;
reg [`VREG_WIDTH-1:0] color [0:8];

reg signed[23:0] edge1[0:2];
reg signed[23:0] edge2[0:2];
reg signed[23:0] edge3[0:2];

reg signed[23:0] temptempEdge1[0:1];
reg signed[23:0] temptempEdge2[0:1];
reg signed[23:0] temptempEdge3[0:1];

reg signed[23:0] tempEdge1[0:1];
reg signed[23:0] tempEdge2[0:1];
reg signed[23:0] tempEdge3[0:1];

reg signed[`REG_WIDTH-1:0] fragmentX[0:2];
reg signed[`REG_WIDTH-1:0] fragmentY[0:2];

reg signed[`REG_WIDTH-1:0] fragmentStartX;
reg signed[`REG_WIDTH-1:0] fragmentEndX;
reg signed[`REG_WIDTH-1:0] fragmentStartY;
reg signed[`REG_WIDTH-1:0] fragmentEndY;

//reg [`REG_WIDTH-1:0] fragmentBuffer[255999:0]; // 640 x 400

reg signed[`REG_WIDTH-1:0] min_x;
reg signed[`REG_WIDTH-1:0] max_x;
reg signed[`REG_WIDTH-1:0] min_y;
reg signed[`REG_WIDTH-1:0] max_y;

reg signed [`REG_WIDTH-1:0] negOne;
reg flag[0:2];
reg [`REG_WIDTH-1:0]edge_result[0:2];

reg [10:0] i;
reg [10:0] j;

initial
begin
	 negOne = -1;
    is_setvertex = 0;
    is_startprimitive = 0;
    is_endprimitive = 0;
    is_draw = 0;
    currentState = 0;
	 O_FRAMESTALL = 0;
	 currentVertex = 0;
	 currentTriangle = 0;
end

/** always @(posedge I_CLOCK)
begin
 
  if (I_LOCK == 1'b1)
  begin 
          
  end
end  **/

always @(negedge I_CLOCK)
begin
  if (I_LOCK == 1'b1)
  begin 
		if(I_Opcode == `OP_SETVERTEX)
		begin
			vertices[currentVertex] <= I_Vertex;
			color[currentVertex] <= I_ColorIn;
			currentVertex = currentVertex + 1;
		end
      if(currentState == 0 && I_Opcode == `OP_DRAW)
      begin
			 O_FRAMESTALL <= 1;	
          for(i = 0; i < 3; i=i+1)
          begin
              fragmentX[i] <= (((vertices[i][31:16])+640))<<5;
              fragmentY[i] <= (((vertices[i][47:32])+640))<<4;
          end
          currentState=currentState+1;
      end
		else if(currentState == 1)
		begin
			 for(i = 0; i < 3; i=i+1)
          begin
              fragmentX[i] <= (fragmentX[i]>>7)<<1;
              fragmentY[i] <= (fragmentY[i]>>7)<<1;
          end 
          currentState=currentState+1;
		end
      else if(currentState == 2)
      begin
       //edgefunction edge_0 = edgefunctionsetup(fragment_x[2], fragment_y[2], fragment_x[1], fragment_y[1]);
          edge1[0] <= fragmentY[2] - fragmentY[1];
          edge1[1] <= fragmentX[1] - fragmentX[2];
          
          
       //edgefunction edge_1 = edgefunctionsetup(fragment_x[0], fragment_y[0], fragment_x[2], fragment_y[2]);
          edge2[0] <= fragmentY[0] - fragmentY[2];
          edge2[1] <= fragmentX[2] - fragmentX[0];
          
            
       //edgefunction edge_2 = edgefunctionsetup(fragment_x[1], fragment_y[1], fragment_x[0], fragment_y[0]);
          edge3[0] <= fragmentY[1] - fragmentY[0];
          edge3[1] <= fragmentX[0] - fragmentX[1];
          
       
          currentState=currentState+1;
      end
		else if(currentState == 3)
		begin
			temptempEdge1[0] <= ((negOne * edge1[0]));
			temptempEdge1[1] <= ((negOne * edge1[1]));
			temptempEdge2[0] <= ((negOne * edge2[0]));
			temptempEdge2[1] <= ((negOne * edge2[1]));
			temptempEdge3[0] <= ((negOne * edge3[0]));
			temptempEdge3[1] <= ((negOne * edge3[1]));
			currentState=currentState+1;
		end
		else if(currentState == 4)
		 begin 
			tempEdge1[0] <= ((temptempEdge1[0]* fragmentX[1]));
			tempEdge1[1] <= ((temptempEdge1[1]* fragmentY[1]));
			tempEdge2[0] <= ((temptempEdge2[0]* fragmentX[2]));
			tempEdge2[1] <= ((temptempEdge2[1]* fragmentY[2]));
			tempEdge3[0] <= ((temptempEdge3[0]* fragmentX[0]));
			tempEdge3[1] <= ((temptempEdge3[1]* fragmentY[0]));
			currentState=currentState+1;
		end
      else if(currentState == 5)
      begin
			edge1[2] <= tempEdge1[0] + tempEdge1[1];
			edge2[2] <= tempEdge2[0] + tempEdge2[1];
			edge3[2] <= tempEdge3[0] + tempEdge3[1];
       // float min_x = fragment_x[0];
          min_x <= fragmentX[0];
      //  float max_x = fragment_x[0];
          max_x<= fragmentX[0];
      //  float min_y = fragment_y[0];
          min_y <= fragmentY[0];
      //  float max_y = fragment_y[0];
          max_y <= fragmentY[0];
        currentState=currentState+1;
      end
      
       else if(currentState >= 6 && currentState <= 8)
       begin
           for(i=1; i<3; i=i+1)
            begin
              if(min_x > fragmentX[i])
              begin
                   min_x <= fragmentX[i];
              end
              if(max_x < fragmentX[i])
              begin
                   max_x <= fragmentX[i];
              end
              if(min_y > fragmentY[i])
              begin
                   min_y <= fragmentY[i];
              end
              if(max_y < fragmentY[i])
              begin
                   max_y <= fragmentY[i];
              end
            end
            currentState=currentState+1;
        end

    
		 else if(currentState == 9)
		 begin
			 if(min_x < 0) begin
				  min_x <= 0;
			 end
			if(max_x >= 639) begin
				  max_x <= 639;
			 end
			 if(min_y < 0) begin
				  min_y <= 0;
			 end
			 if(max_y >= 399) begin
				  max_y <= 399;
			 end
			  currentState=currentState+1;
		 end
    
		 else if(currentState == 10)
		 begin
				fragmentStartX <= min_x;
				fragmentEndX   <= max_x;
				fragmentStartY <= min_y;
				fragmentEndY   <= max_y;
			currentState = currentState + 1'b1;	
		 end    
        
        //Traverse
	  else if(currentState == 11)
	  begin
		 i = fragmentStartY;
		 j = fragmentStartX;
		 currentState = currentState + 1'b1;
	  end
	  
	  else if(currentState == 12)
	  begin
			/**if(inside(edge_0, (j + 0.5), (i + 0.5))
				&& inside(edge_1, (j + 0.5), (i + 0.5))
				&& inside(edge_2, (j + 0.5), (i + 0.5))) **/

   edge_result[0] = (((edge1[0] * j) + (edge1[1] * i)) + edge1[2]);

	if (edge_result[0][15] == 0)
		flag[0] = 1;
	else if (edge_result[0][15] == 1)
		flag[0] = 0;
	else if (edge1[0][15] == 1)
		flag[0] = 1;
	else if (edge1[0][15] == 0)
		flag[0] = 0;
	else if (edge1[1][15] == 1)
		flag[0] = 0;
	else 
		flag[0] = 0;
		
	edge_result[1] = (((edge2[0] * j) + (edge2[1] * i)) + edge2[2]);

	if (edge_result[1][15] == 0)
		flag[1] = 1;
	else if (edge_result[1][15] == 1)
		flag[1] = 0;
	else if (edge2[0][15] == 1)
		flag[1] = 1;
	else if (edge2[0][15] == 0)
		flag[1] = 0;
	else if (edge2[1][15] == 1)
		flag[1] = 1;
	else 
		flag[1] = 0;
		
	edge_result[2] = (((edge3[0] * j) + (edge3[1] * i)) + edge3[2]);

	if (edge_result[2][15] == 0)
		flag[2] = 1;
	else if (edge_result[2][15] == 1)
		flag[2] = 0;
	else if (edge3[0][15] == 1)
		flag[2] = 1;
	else if (edge3[0][15] == 0)
		flag[2] = 0;
	else if (edge3[1][15] == 1)
		flag[2] = 0;
	else 
		flag[2] = 0;
		
		if(flag[0] == 1 && flag[1] == 1 && flag[2] == 1)	
			begin
			 O_ADDROut <= i*640+j;
			 O_ColorOut <= color[currentTriangle];
			end
  
		  j = j+1;
		  if(j==fragmentEndX)
		  begin
		  i = i+1;
		  end
		  
		  if(j==fragmentEndX && i==fragmentEndY)
		  begin
		  O_FRAMESTALL <= 0;
		  currentState <= 0;
		  end
		  
		  if(j==fragmentEndX)
		  begin  
		  j = fragmentStartX;
		  end		  
	  end       
  end
end


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

	  HexOut <= I_Opcode;
	  LedGOut <= i;
	  LedROut <= currentState;
  end // if (I_LOCK == 0) begin
end // always @(negedge I_CLOCK)

assign O_LEDR = LedROut;
assign O_LEDG = LedGOut;


endmodule