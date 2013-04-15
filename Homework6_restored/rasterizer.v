`include "global_def.h"

module Rasterizer(
    I_CLOCK,
    I_LOCK,
    I_Opcode,
    I_Vertex,
	 I_ColorIn,
	 O_ColorOut,
	 O_ADDROut,
    O_LOCK
);
input I_CLOCK;
input I_LOCK;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input [`VREG_WIDTH-1:0] I_Vertex;
input [`VREG_WIDTH-1:0] I_ColorIn;

output O_LOCK;
output [17:0] O_ADDROut;
output [15:0] O_ColorOut;

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

reg [`REG_WIDTH-1:0] edge1[0:2];
reg [`REG_WIDTH-1:0] edge2[0:2];
reg [`REG_WIDTH-1:0] edge3[0:2];

reg [`REG_WIDTH-1:0] fragmentX[0:2];
reg [`REG_WIDTH-1:0] fragmentY[0:2];

reg [`REG_WIDTH-1:0] fragmentStartX;
reg [`REG_WIDTH-1:0] fragmentEndX;
reg [`REG_WIDTH-1:0] fragmentStartY;
reg [`REG_WIDTH-1:0] fragmentEndY;

reg [`REG_WIDTH-1:0] fragmentBuffer[255999:0]; // 640 x 400

reg [`REG_WIDTH-1:0] min_x;
reg [`REG_WIDTH-1:0] max_x;
reg [`REG_WIDTH-1:0] min_y;
reg [`REG_WIDTH-1:0] max_y;

reg [8:0] i;
reg [8:0] j;

initial
begin
    is_setvertex = 0;
    is_startprimitive = 0;
    is_endprimitive = 0;
    is_draw = 0;
    currentState = 0;
end

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
      if(currentState == 0)
      begin
          for(i = 0; i < 3; i=i+1)
          begin
              //fragment_x[i] = (current_triangle.v[i].x + 5) * 64.0f;
              fragmentX[i] <= (vertices[currentVertex][15:0] + 3'b101 <<8) * 7'b1000000<<8;
              //fragment_y[i] = (current_triangle.v[i].y + 16'b5<<8) * 40.0f;
              fragmentY[i] <= (vertices[currentVertex][31:16] + 3'b101 <<8) * 6'b101000<<8;
          end
          currentState=currentState+1;
      end
      if(currentState == 1)
      begin
       //edgefunction edge_0 = edgefunctionsetup(fragment_x[2], fragment_y[2], fragment_x[1], fragment_y[1]);
          edge1[0] <= fragmentY[2] - fragmentY[1];
          edge1[1] <= fragmentX[1] - fragmentX[2];
          edge1[2] <= (((-1<<7) * edge1[0]) * fragmentX[1]) + (((-1<<7) * edge1[1]) * fragmentY[1]);
          
       //edgefunction edge_1 = edgefunctionsetup(fragment_x[0], fragment_y[0], fragment_x[2], fragment_y[2]);
          edge2[0] <= fragmentY[0] - fragmentY[2];
          edge2[1] <= fragmentX[2] - fragmentX[0];
          edge2[2] <= (((-1<<7) * edge2[0]) * fragmentX[2]) + (((-1<<7) * edge2[1]) * fragmentY[2]);
            
       //edgefunction edge_2 = edgefunctionsetup(fragment_x[1], fragment_y[1], fragment_x[0], fragment_y[0]);
          edge3[0] <= fragmentY[1] - fragmentY[0];
          edge3[1] <= fragmentX[0] - fragmentX[1];
          edge3[2] <= (((-1<<7) * edge3[0]) * fragmentX[0]) + (((-1<<7) * edge3[1]) * fragmentY[0]);
       
          currentState=currentState+1;
      end
      
      if(currentState == 2)
      begin
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
      
       if(currentState >= 3 && currentState <= 5)
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
              if(max_x > fragmentX[i])
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
              if(max_y > fragmentY[i])
              begin
                   max_y <= fragmentY[i];
              end
     //   }
            end
            currentState=currentState+1;
        end

    
    if(currentState == 6)
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
    
    if(currentState == 7)
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
         
    end    
        
        //Traverse
        if(currentState == 8)
        begin
    //    for(int i = fragment_start_y; i < fragment_end_y; i++){
        for(i = fragmentStartY; i < fragmentEndY; i=i+1)
        begin
     //       for (int j = fragment_start_x; j < fragment_end_x; j++) {
           for(j = fragmentStartX; j<fragmentEndX; j=j+1) 
           begin
           
           //       edgeResult[0] <= edge1[0]*(j) + edge1[1]*(i) + edge1[2];
           //       edgeResult[1] <= edge2[0]*(j) + edge2[1]*(i) + edge2[2];
           //       edgeResult[2] <= edge3[0]*(j) + edge3[1]*(i) + edge3[2];
                  
                  if(((edge1[0]*(j) + edge1[1]*(i) + edge1[2]) > 0 || edge1[0] > 0 || edge1[1] > 0)&&
                     ((edge2[0]*(j) + edge2[1]*(i) + edge2[2]) > 0 || edge2[0] > 0 || edge2[1] > 0)&&
                     ((edge3[0]*(j) + edge3[1]*(i) + edge3[2]) > 0 || edge3[0] > 0 || edge3[1] > 0)) 
                     begin
                      fragmentBuffer[i*640+j] <= color[currentState];
							 O_ADDROut <= i*640*j;
							 O_ColorOut <= color[currentState];
                     end
           
       //         if(inside(edge_0, (j + 0.5), (i + 0.5))
       //         && inside(edge_1, (j + 0.5), (i + 0.5))
       //         && inside(edge_2, (j + 0.5), (i + 0.5))){
                 //TODO: FILL IN WITH STUPID CONDITION AS ABOVE
                 
       //             fragmentbuffer[i][j].depth = depth;
       //             fragmentbuffer[i][j].r = r;
       //             fragmentbuffer[i][j].r = color[currentState][15:0];
       //             fragmentbuffer[i][j].g = g;
       //             fragmentbuffer[i][j].b = b;
       //             fragmentbuffer[i][j].a = a;
                      
       //
       //             if ((r+g+b)>0) printf("framebufer [%d][%d] r:%d g:%d b:%d a:%d \n",
       //               i, j, fragmentbuffer[i][j].r,
       //                 fragmentbuffer[i][j].g,
       //                    fragmentbuffer[i][j].b,
       //                           fragmentbuffer[i][j].a); 
        
       //         }
       //     }                
           end
       end
       currentState <= 0;
     end
  end
end

endmodule