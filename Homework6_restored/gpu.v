module Gpu (
  I_CLK, 
  I_RST_N,
  I_VIDEO_ON, 
  // GPU-SRAM interface
  I_GPU_DATA, 
  I_GPU_ADDR,
  I_GPU_COLOR,
  O_GPU_DATA,
  O_GPU_ADDR,
  O_GPU_READ,
  O_GPU_WRITE
);

input	I_CLK;
input I_RST_N;
input	I_VIDEO_ON;

// GPU-SRAM interface
input       [15:0] I_GPU_DATA;
input       [17:0] I_GPU_ADDR;
input			[63:0] I_GPU_COLOR;
output reg  [15:0] O_GPU_DATA;
output reg  [17:0] O_GPU_ADDR;
output reg         O_GPU_WRITE;
output reg         O_GPU_READ;

/////////////////////////////////////////
// Example code goes here 
//
// ## Note
// It is highly recommended to play with this example code first so that you
// could get familiarized with a set of output ports. By doing so, you would
// get the hang of dealing with vector (graphics) objects in pixel frame.
/////////////////////////////////////////
//
reg [24:0] count;
reg [9:0]  rowInd;
reg [9:0]  colInd;

always @(posedge I_CLK or negedge I_RST_N)
begin
	if (!I_RST_N) begin
		O_GPU_ADDR <= 16'h0000;
		O_GPU_WRITE <= 1'b1;
		O_GPU_READ <= 1'b0;
		O_GPU_DATA <= 
		count <= 0;
	end else begin
		if (!I_VIDEO_ON) begin
			//count <= count + 1;
			O_GPU_ADDR <= I_GPU_ADDR;
			O_GPU_DATA <= {4'h0, I_GPU_COLOR[11:8],I_GPU_COLOR[27:24],I_GPU_COLOR[43:40]};
			O_GPU_WRITE <= 1'b1;
			O_GPU_READ <= 1'b0;
			
		end
	end
end

always @(posedge I_CLK or negedge I_RST_N)
begin
  if (!I_RST_N) begin
    colInd <= 0;
  end else begin
    if (!I_VIDEO_ON) begin
      if (colInd < 639)
        colInd <= colInd + 1;
      else
        colInd <= 0;
    end
  end
end

always @(posedge I_CLK or negedge I_RST_N)
begin
  if (!I_RST_N) begin
    rowInd <= 0;
  end else begin
    if (!I_VIDEO_ON) begin
      if (colInd == 0) begin
        if (rowInd < 399)
          rowInd <= rowInd + 1;
        else
          rowInd <= 0;
      end
    end
  end
end

endmodule
