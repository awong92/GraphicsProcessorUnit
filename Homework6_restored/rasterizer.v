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
	 O_FRAMESTALL
);
input I_CLOCK;
input I_LOCK;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input [`VREG_WIDTH-1:0] I_Vertex;
input [`VREG_WIDTH-1:0] I_ColorIn;

output O_LOCK;
output reg [17:0] O_ADDROut;
output reg [15:0] O_ColorOut;
output reg O_FRAMESTALL;
/*
* State machine variables dawg
*/
reg is_setvertex;
reg is_startprimitive;
reg is_endprimitive;
reg is_draw;

reg [`VREG_WIDTH-1:0] vertices [0:8];
reg [3:0] currentVertex;
reg [8:0] currentState;
reg [`VREG_WIDTH-1:0] color [0:8];

reg signed[`REG_WIDTH-1:0] edge1[0:2];
reg signed[`REG_WIDTH-1:0] edge2[0:2];
reg signed[`REG_WIDTH-1:0] edge3[0:2];

reg signed[`REG_WIDTH-1:0] temptempEdge1[0:1];
reg signed[`REG_WIDTH-1:0] temptempEdge2[0:1];
reg signed[`REG_WIDTH-1:0] temptempEdge3[0:1];

reg signed[`REG_WIDTH-1:0] tempEdge1[0:1];
reg signed[`REG_WIDTH-1:0] tempEdge2[0:1];
reg signed[`REG_WIDTH-1:0] tempEdge3[0:1];

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
              //fragment_x[i] = (current_triangle.v[i].x + 5) * 64.0f;
              fragmentX[i] <= (((vertices[i][31:16])+640))*32;
				  // + 3'b101 <<7) * 4'b1000<<7;
				  //fragmentX[i] <= (vertices[i][31:16] + 3'b101 <<8) * 7'b1000000<<8;
              //fragment_y[i] = (current_triangle.v[i].y + 16'b5<<8) * 40.0f;
              fragmentY[i] <= (((vertices[i][47:32])+640))*16;
				  // fragmentY[i] <= (vertices[i][47:32] + 3'b101 <<8) * 6'b101000<<8;
          end
          currentState=currentState+1;
      end
		else if(currentState == 1)
		begin
			 for(i = 0; i < 3; i=i+1)
          begin
              //fragment_x[i] = (current_triangle.v[i].x + 5) * 64.0f;
              fragmentX[i] <= (fragmentX[i]>>7)*2;
				  // + 3'b101 <<7) * 4'b1000<<7;
				  //fragmentX[i] <= (vertices[i][31:16] + 3'b101 <<8) * 7'b1000000<<8;
              //fragment_y[i] = (current_triangle.v[i].y + 16'b5<<8) * 40.0f;
              fragmentY[i] <= (fragmentY[i]>>7)*2;
				  // fragmentY[i] <= (vertices[i][47:32] + 3'b101 <<8) * 6'b101000<<8;
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
		/**	if(edge1[0][15] == 1'b0)
			begin
				temptempEdge1[0] <= ((negOne * edge1[0])>>>7);
			end
			else
			begin
				temptempEdge1[0] <= ((negOne * edge1[0])>>7);
			end
			
			if(edge1[1][15] == 1'b0)
			begin
				temptempEdge1[1] <= ((negOne * edge1[1])>>>7);
			end
			else
			begin
				temptempEdge1[1] <= ((negOne * edge1[1])>>7);
			end
			
			if(edge2[0][15] == 1'b0)
			begin
					temptempEdge2[0] <= ((negOne * edge2[0])>>>7);
			end
			else
			begin
					temptempEdge2[0] <= ((negOne * edge2[0])>>7);
			end
			
			if(edge2[1][15] == 1'b0)
			begin
				temptempEdge2[1] <= ((negOne * edge2[1])>>>7);
			end
			else
			begin
				temptempEdge2[1] <= ((negOne * edge2[1])>>7);
			end
			
			if(edge3[0][15] == 1'b0)
			begin
				temptempEdge3[0] <= ((negOne * edge3[0])>>>7);
			end
			else
			begin
				temptempEdge3[0] <= ((negOne * edge3[0])>>7);
			end
			
			if(edge3[1][15] == 1'b0)
			begin
				temptempEdge3[1] <= ((negOne * edge3[1])>>>7);
			end
			else
			begin
				temptempEdge3[1] <= ((negOne * edge3[1])>>7);
			end **/
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
		/**	if((temptempEdge1[0][15] == 1'b1 && fragmentX[1][15]==1'b1) || (temptempEdge1[0][15] == 1'b0 && fragmentX[1][15]==1'b0))
			begin
				tempEdge1[0] <= ((temptempEdge1[0]* fragmentX[1])>>7);
			end
			else
			begin
				tempEdge1[0] <= ((temptempEdge1[0]* fragmentX[1])>>>7);
			end
			
			if((temptempEdge1[1][15] == 1'b1 && fragmentY[1][15] ==1'b1) || (temptempEdge1[1][15] == 1'b0 && fragmentY[1][15] ==1'b0))
			begin
				tempEdge1[1] <= ((temptempEdge1[1]* fragmentY[1])>>7);
			end
			else
			begin
				tempEdge1[1] <= ((temptempEdge1[1]* fragmentY[1])>>>7);
			end
			
			if((temptempEdge2[0][15] == 1'b1 && fragmentX[2][15]==1'b1) || (temptempEdge2[0][15] == 1'b0 && fragmentX[2][15]==1'b0))
			begin
				tempEdge2[0] <= ((temptempEdge2[0]* fragmentX[2])>>7);
			end
			else
			begin
				tempEdge2[0] <= ((temptempEdge2[0]* fragmentX[2])>>>7);
			end
			
			if((temptempEdge2[1][15] == 1'b1 && fragmentY[2][15]==1'b1) || (temptempEdge2[1][15] == 1'b0 && fragmentY[2][15]==1'b0))
			begin
				tempEdge2[1] <= ((temptempEdge2[1]* fragmentY[2])>>7);
			end
			else
			begin
				tempEdge2[1] <= ((temptempEdge2[1]* fragmentY[2])>>>7);
			end
			
			if((temptempEdge3[0][15] == 1'b1 && fragmentX[0][15]==1'b1) || (temptempEdge3[0][15] == 1'b0 && fragmentX[0][15]==1'b0))
			begin
				tempEdge3[0] <= ((temptempEdge3[0]* fragmentX[0])>>7);
			end
			else
			begin
				tempEdge3[0] <= ((temptempEdge3[0]* fragmentX[0])>>>7);
			end
			
			if((temptempEdge3[1][15] == 1'b1 && fragmentY[0][15]==1'b1) || (temptempEdge3[1][15] == 1'b0 && fragmentY[0][15]==1'b0))
			begin
				tempEdge3[1] <= ((temptempEdge3[1]* fragmentY[0])>>7);
			end
			else
			begin
				tempEdge3[1] <= ((temptempEdge3[1]* fragmentY[0])>>>7);
			end	 **/
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
     //   for(int i = 1; i < 3; i++){
     //    for(i=1; i < 3; i++)
           for(i=1; i<3; i=i+1)
            begin
     //       if(min_x > fragment_x[i]){
     //           min_x = fragment_x[i];
     //       }
              if(min_x > fragmentX[i])
              begin
                   min_x <= fragmentX[i];
              end
     //       if(max_x < fragment_x[i]){
     //           max_x = fragment_x[i];
     //       }
              if(max_x < fragmentX[i])
              begin
                   max_x <= fragmentX[i];
              end
     //       if(min_y > fragment_y[i]){
     //           min_y = fragment_y[i];
     //       }
              if(min_y > fragmentY[i])
              begin
                   min_y <= fragmentY[i];
              end
      //      if(max_y < fragment_y[i]){
      //          max_y = fragment_y[i];
      //      }
              if(max_y < fragmentY[i])
              begin
                   max_y <= fragmentY[i];
              end
     //   }
            end
            currentState=currentState+1;
        end

    
		 else if(currentState == 9)
		 begin
		 //    if(min_x < 0){ min_x = 0; }
		 //    if(max_x >= 639){ max_x = 639;}
		 //    if(min_y < 0){ min_y = 0;}
		 //    if(max_y >= 399){ max_y = 399;}
		 
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
		 //    fragment_start_x = min_x;
		 //    fragment_end_x = max_x;
		  //   fragment_start_y = min_y;
		  //   fragment_end_y = max_y;
				fragmentStartX <= min_x;
				fragmentEndX   <= max_x;
				fragmentStartY <= min_y;
				fragmentEndY   <= max_y;
		 
		 //    float depth = current_triangle.v[0].z;
		//     float r = current_triangle.v[0].r;
		 //    float g = current_triangle.v[0].g;
		//     float b = current_triangle.v[0].b;
		 //    float a = current_triangle.v[0].a;
			currentState = currentState + 1'b1;	
		 end    
        
        //Traverse
	  else if(currentState == 11)
	  begin
 //    for(int i = fragment_start_y; i < fragment_end_y; i++){
		 i = fragmentStartY;
		 j = fragmentStartX;
		 currentState = currentState + 1'b1;
	  end
	  
	  else if(currentState == 12)
	  begin		
			if(((edge1[0]*(j) + edge1[1]*(i) + edge1[2]) > 0 || edge1[0] > 0 || edge1[1] > 0)&&
						((edge2[0]*(j) + edge2[1]*(i) + edge2[2]) > 0 || edge2[0] > 0 || edge2[1] > 0)&&
						((edge3[0]*(j) + edge3[1]*(i) + edge3[2]) > 0 || edge3[0] > 0 || edge3[1] > 0)) 
			begin
			 //fragmentBuffer[i*640+j] <= color[currentState];
			 O_ADDROut <= i*640*j;
			 O_ColorOut <= color[currentState];
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
endmodule