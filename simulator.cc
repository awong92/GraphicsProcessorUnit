#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <bitset>
#include <stdint.h>
#include <cstring>
#include <limits.h>
#include <math.h>
#include "simulator.h"

#define DEBUG
// #define GRAPH_DEBUG 

using namespace std;

ScalarRegister g_condition_code_register;
ScalarRegister g_scalar_registers[NUM_SCALAR_REGISTER];
VectorRegister g_vector_registers[NUM_VECTOR_REGISTER];

unsigned char g_memory[MEMORY_SIZE];
vector<TraceOp> g_trace_ops;

unsigned int g_instruction_count = 0;


#define PI 3.14159265

typedef struct matrix_struct {
	float mat[4][4];
	unsigned char r,g,b,a;
} matrix;

typedef struct vertex_struct {
	float x,y,z,w;
	float r,g,b,a;
} vertex;

typedef struct triangle_struct {
	int current_vertex;
	vertex v[3];
} triangle;

typedef struct fragment_struct {
	short int x,y;
	float depth;
	float r,g,b,a;
} fragment;

typedef struct pixel_struct {
	int depth;
	unsigned char r,g,b,a;
} pixel;



//matrix
//assumption - destination : 16 matrix = 16 X 20 scalar registers
matrix current_matrix;
matrix* matrixstack;
int matrixstackpointer;

//current_vertex
vertex current_vertex;

//current_triangle
triangle current_triangle;

//fragmentbuffer
fragment** fragmentbuffer;
int fragment_start_x;
int fragment_end_x;
int fragment_start_y;
int fragment_end_y;

//framebuffer
pixel** framebuffer;

bool is_setvertex; 
bool is_startprimitive; 
bool is_endprimitive;
bool is_draw; 




// InitializeGPUVariables 
void InitializeGPUVariables(void)
{

  is_setvertex = false; 
  is_startprimitive = false; 
  is_endprimitive = false; 
  is_draw = false; 

	//current_matrix initialization
	for(int j = 0; j < 4; j++){
		for(int k = 0; k < 4; k++){
			current_matrix.mat[j][k] = 0;
			if(j == k){
				current_matrix.mat[j][k] = 1;
			}
		}
	}
	current_matrix.r = 0;
	current_matrix.g = 0;
	current_matrix.b = 0;
	current_matrix.a = 0;

	//matrixstack initialization
	matrixstack = new matrix[2];
	for(int i = 0; i < 2; i++){
		for(int j = 0; j < 4; j++){
			for(int k = 0; k < 4; k++){
				matrixstack[i].mat[j][k] = 0;
				if(j == k){
					matrixstack[i].mat[j][k] = 1;
				}
			}
		}
		matrixstack[i].r = 0;
		matrixstack[i].g = 0;
		matrixstack[i].b = 0;
		matrixstack[i].a = 0;
	}
	matrixstackpointer = -1;

	//current_vertex initialization
	current_vertex.x = 0;
	current_vertex.y = 0;
	current_vertex.z = 0;
	current_vertex.w = 1;
	current_vertex.r = 0;
	current_vertex.g = 0;
	current_vertex.b = 0;
	current_vertex.a = 0;

	//current_triangle initialization
	current_triangle.current_vertex = 0;
	for(int i = 0; i < 3; i++){
		current_triangle.v[i].x = 0;
		current_triangle.v[i].y = 0;
		current_triangle.v[i].z = 0;
		current_triangle.v[i].w = 1;
		current_triangle.v[i].r = 0;
		current_triangle.v[i].g = 0;
		current_triangle.v[i].b = 0;
		current_triangle.v[i].a = 0;
	}

	//fragmentbuffer initialization
	fragmentbuffer = new fragment *[400];
	for(int i = 0; i < 400; i++){
		fragmentbuffer[i] = new fragment[640];
	}

	for(int i = 0; i < 400; i++){
		for (int j=0; j < 640; j++) {
			fragmentbuffer[i][j].depth = 3;
			fragmentbuffer[i][j].r = 0;
			fragmentbuffer[i][j].g = 0;
			fragmentbuffer[i][j].b = 0;
			fragmentbuffer[i][j].a = 0;
		}
	}
	fragment_start_x = 0;
	fragment_end_x = 0;
	fragment_start_y = 0;
	fragment_end_y = 0;

	//framebuffer initialization
	framebuffer = new pixel *[400];
	for(int i = 0; i < 400; i++){
		framebuffer[i] = new pixel[640];
	}

	for(int i = 0; i < 400; i++){
		for (int j=0; j < 640; j++) {
			framebuffer[i][j].depth = 3;
			framebuffer[i][j].r = 0;
			framebuffer[i][j].g = 0;
			framebuffer[i][j].b = 0;
			framebuffer[i][j].a = 0;
		}
	}
}


void setvertex(float x_value, float y_value, float z_value){
	current_vertex.x = x_value;
	current_vertex.y = y_value;
	current_vertex.z = z_value;
}

void color(unsigned char r_value, unsigned char g_value, unsigned char b_value){
	current_matrix.r = r_value;
	current_matrix.g = g_value;
	current_matrix.b = b_value;
}

void rotate(float angle, float z_value){
	//Prepare Operand
	matrix bak_matrix;
	for(int j = 0; j < 4; j++){
		for(int k = 0; k < 4; k++){
			bak_matrix.mat[j][k] = current_matrix.mat[j][k];
		}
	}

	matrix tmp_matrix;
	for(int j = 0; j < 4; j++){
		for(int k = 0; k < 4; k++){
			tmp_matrix.mat[j][k] = 0;
			if(j == k){
				tmp_matrix.mat[j][k] = 1;
			}
		}
	}

	if(z_value < 0){
		angle = (-1) * angle;
	}

	tmp_matrix.mat[0][0] = cos(angle*PI/180);
	tmp_matrix.mat[1][0] = (-1) * sin(angle*PI/180);
	tmp_matrix.mat[0][1] = sin(angle*PI/180);
	tmp_matrix.mat[1][1] = cos(angle*PI/180);

	//Matrix Multiply
	for(int i = 0; i < 4; i++){
		for(int j = 0; j < 4; j++){
			float result = 0;
			for(int k = 0; k < 4; k++){
				//result = result + (tmp_matrix.mat[i][k] * bak_matrix.mat[k][j]);
				result = result + (bak_matrix.mat[i][k] * tmp_matrix.mat[k][j]);
			}
			current_matrix.mat[i][j] = result;
		}
	}
}


void translate(float x_value, float y_value){
	//Prepare Operand
	matrix bak_matrix;
	for(int j = 0; j < 4; j++){
		for(int k = 0; k < 4; k++){
			bak_matrix.mat[j][k] = current_matrix.mat[j][k];
		}
	}

	matrix tmp_matrix;
	for(int j = 0; j < 4; j++){
		for(int k = 0; k < 4; k++){
			tmp_matrix.mat[j][k] = 0;
			if(j == k){
				tmp_matrix.mat[j][k] = 1;
			}
		}
	}

	tmp_matrix.mat[0][3] = x_value;
	tmp_matrix.mat[1][3] = y_value;

	//Matrix Multiply
	for(int i = 0; i < 4; i++){
		for(int j = 0; j < 4; j++){
			float result = 0;
			for(int k = 0; k < 4; k++){
				//result = result + (tmp_matrix.mat[i][k] * bak_matrix.mat[k][j]);
				result = result + (bak_matrix.mat[i][k] * tmp_matrix.mat[k][j]);
			}
			current_matrix.mat[i][j] = result;
		}
	}
}


void scale(float x_value, float y_value){
	//Prepare Operand
	matrix bak_matrix;
	for(int j = 0; j < 4; j++){
		for(int k = 0; k < 4; k++){
			bak_matrix.mat[j][k] = current_matrix.mat[j][k];
		}
	}

	matrix tmp_matrix;
	for(int j = 0; j < 4; j++){
		for(int k = 0; k < 4; k++){
			tmp_matrix.mat[j][k] = 0;
			if(j == k){
				tmp_matrix.mat[j][k] = 1;
			}
		}
	}

	tmp_matrix.mat[0][0] = x_value;
	tmp_matrix.mat[1][1] = y_value;

	//Matrix Multiply
	for(int i = 0; i < 4; i++){
		for(int j = 0; j < 4; j++){
			float result = 0;
			for(int k = 0; k < 4; k++){
				//result = result + (tmp_matrix.mat[i][k] * bak_matrix.mat[k][j]);
				result = result + (bak_matrix.mat[i][k] * tmp_matrix.mat[k][j]);
			}
			current_matrix.mat[i][j] = result;
		}
	}
}


void pushmatrix(){
	if(matrixstackpointer < 15){
		matrixstackpointer = matrixstackpointer + 1;
		for(int j = 0; j < 4; j++){
			for(int k = 0; k < 4; k++){
				matrixstack[matrixstackpointer].mat[j][k] = current_matrix.mat[j][k];
			}
		}
		matrixstack[matrixstackpointer].r = current_matrix.r;
		matrixstack[matrixstackpointer].g = current_matrix.g;



		matrixstack[matrixstackpointer].b = current_matrix.b;
		matrixstack[matrixstackpointer].a = current_matrix.a;
	}
}

void loadidentity(){
	//current_matrix initialization
	for(int j = 0; j < 4; j++){
		for(int k = 0; k < 4; k++){
			current_matrix.mat[j][k] = 0;
			if(j == k){
				current_matrix.mat[j][k] = 1;
			}
		}
	}

	current_matrix.r = 0;
	current_matrix.g = 0;
	current_matrix.b = 0;
	current_matrix.a = 0;
}



void popmatrix(){
	if(matrixstackpointer >= 0){
		for(int j = 0; j < 4; j++){
			for(int k = 0; k < 4; k++){
				current_matrix.mat[j][k] = matrixstack[matrixstackpointer].mat[j][k];
			}
		}
		current_matrix.r = matrixstack[matrixstackpointer].r;
		current_matrix.g = matrixstack[matrixstackpointer].g;
		current_matrix.b = matrixstack[matrixstackpointer].b;
		current_matrix.a = matrixstack[matrixstackpointer].a;

		matrixstackpointer = matrixstackpointer - 1;
	}
}


void vertexOperation(bool is_setvertex){
	if(is_setvertex){
		//Color
		current_vertex.r = current_matrix.r;
		current_vertex.g = current_matrix.g;
		current_vertex.b = current_matrix.b;
		current_vertex.a = current_matrix.a;

		float x_value = current_vertex.x;
		float y_value = current_vertex.y;
#ifdef GRAPH_DEBUG 
		printf("current_vertex r:%d g:%d b:%d a:%d \n",
		       current_matrix.r, current_matrix.g, current_matrix.b, current_matrix.a);
#endif 
		current_vertex.x = 0;
		current_vertex.y = 0;

		float x_result = 0;
		x_result += current_matrix.mat[0][0] * x_value;
		x_result += current_matrix.mat[0][1] * y_value;
		x_result += current_matrix.mat[0][3] * 1;
		current_vertex.x = x_result;

		float y_result = 0;
		y_result += current_matrix.mat[1][0] * x_value;
		y_result += current_matrix.mat[1][1] * y_value;
		y_result += current_matrix.mat[1][3] * 1;
		current_vertex.y = y_result;
	}
}



void primitiveAssembly(bool is_startprimitive, bool is_setvertex){
	if(is_startprimitive){
		current_triangle.current_vertex = 0;
	}

#ifdef GRAPH_DEBUG 
	printf("primitive_assembly current_triangle.v[%d].x : %lf, current_triangle.v[i].y : %lf\n",
	       current_triangle.current_vertex, current_vertex.x, current_vertex.y); 
#endif 
			
	if(is_setvertex){
		current_triangle.v[current_triangle.current_vertex] = current_vertex;
		current_triangle.current_vertex++;
	}
	
}

typedef struct edgefunction_struct{
	float a, b, c;
} edgefunction;

edgefunction edgefunctionsetup(float x_value_1, float y_value_1, float x_value_2, float y_value_2){
	float a = (y_value_1 - y_value_2);
	float b = (x_value_2 - x_value_1);

	float c_1 = ((-1) * a) * x_value_2;
	float c_2 = ((-1) * b) * y_value_2;
	float c = c_1 + c_2;

	edgefunction edge;
	edge.a = a;
	edge.b = b;
	edge.c = c;

	return edge;
}

float calculate_edgefunction(edgefunction edge, float x_value, float y_value){
	//printf("%lf\n", (((edge.a * x_value) + (edge.b * y_value)) + edge.c));
	return (((edge.a * x_value) + (edge.b * y_value)) + edge.c);
}

bool inside(edgefunction edge, float x_value, float y_value){
	float edge_result = calculate_edgefunction(edge, x_value, y_value);

	if(edge_result > 0){
		return true;
	}
	if(edge_result < 0){
		return false;
	}
	if(edge.a > 0){
		return true;
	}
	if(edge.a < 0){
		return false;
	}
	if(edge.b > 0){
		return true;
	}
	return false;
}



void rasterationOperation(bool is_endprimitive){
	if(is_endprimitive){
		//Triangle Setup
		float fragment_x[3];
		float fragment_y[3];

		for(int i = 0; i < 3; i++){
			fragment_x[i] = (current_triangle.v[i].x + 5) * 64.0f;
			fragment_y[i] = (current_triangle.v[i].y + 5) * 40.0f;
#ifdef GRAPH_DEBUG			
			printf("current_triangle.v[%d].x : %lf, current_triangle.v[%d].y : %lf r:%d g:%d b:%d \n",
			       i, current_triangle.v[i].x, i, current_triangle.v[i].y, current_triangle.v[i].r, 
			       current_triangle.v[i].g, current_triangle.v[i].b);
			printf("fragment_x[%d] : %lf, fragment_y[%d] : %lf\n",
			       i, fragment_x[i], i, fragment_y[i]);
		
#endif 	
		}

		//Edge Function Setup
		edgefunction edge_0 =
				edgefunctionsetup(fragment_x[2], fragment_y[2], fragment_x[1], fragment_y[1]);
		edgefunction edge_1 =
				edgefunctionsetup(fragment_x[0], fragment_y[0], fragment_x[2], fragment_y[2]);
		edgefunction edge_2 =
				edgefunctionsetup(fragment_x[1], fragment_y[1], fragment_x[0], fragment_y[0]);

		//printf("edgefunction0 : %lf, %lf, %lf\n", edge_0.a, edge_0.b, edge_0.c);
		//printf("edgefunction1 : %lf, %lf, %lf\n", edge_1.a, edge_1.b, edge_1.c);
		//printf("edgefunction2 : %lf, %lf, %lf\n", edge_2.a, edge_2.b, edge_2.c);

		//Traverse Setup
		float min_x = fragment_x[0];
		float max_x = fragment_x[0];
		float min_y = fragment_y[0];
		float max_y = fragment_y[0];

		for(int i = 1; i < 3; i++){
			if(min_x > fragment_x[i]){
				min_x = fragment_x[i];
			}
			if(max_x < fragment_x[i]){
				max_x = fragment_x[i];
			}
			if(min_y > fragment_y[i]){
				min_y = fragment_y[i];
			}
			if(max_y < fragment_y[i]){
				max_y = fragment_y[i];
			}
		}

		if(min_x < 0){ min_x = 0; }
		if(max_x >= 639){ max_x = 639;}
		if(min_y < 0){ min_y = 0;}
		if(max_y >= 399){ max_y = 399;}

		fragment_start_x = min_x;
		fragment_end_x = max_x;
		fragment_start_y = min_y;
		fragment_end_y = max_y;

		float depth = current_triangle.v[0].z;
		float r = current_triangle.v[0].r;
		float g = current_triangle.v[0].g;
		float b = current_triangle.v[0].b;
		float a = current_triangle.v[0].a;
#ifdef GRAPH_DEBUG 
		printf("depth : %lf, r: %lf, g: %lf, b: %lf, a: %lf\n", depth, r, g, b, a);
#endif 
		//Traverse
		for(int i = fragment_start_y; i < fragment_end_y; i++){
			for (int j = fragment_start_x; j < fragment_end_x; j++) {
				if(inside(edge_0, (j + 0.5), (i + 0.5))
				&& inside(edge_1, (j + 0.5), (i + 0.5))
				&& inside(edge_2, (j + 0.5), (i + 0.5))){
				  
				  

					fragmentbuffer[i][j].depth = depth;
					fragmentbuffer[i][j].r = r;
					fragmentbuffer[i][j].g = g;
					fragmentbuffer[i][j].b = b;
					fragmentbuffer[i][j].a = a;

					/* if ((r+g+b)>0) printf("framebufer [%d][%d] r:%d g:%d b:%d a:%d \n",
				  	  i, j, fragmentbuffer[i][j].r,
						fragmentbuffer[i][j].g,
      						fragmentbuffer[i][j].b,
							      fragmentbuffer[i][j].a); 	
					*/ 
				}

			}
		}

	}
}

void zbufferOperation(){
	/*
	printf("zbufferOperation : "
		"fragment_start_x : %d, "
		"fragment_end_x: %d, "
		"fragment_start_y: %d, "
		"fragment_end_y: %d\n", fragment_start_x, fragment_end_x, fragment_start_y, fragment_end_y);
	*/

	for(int i = fragment_start_y; i < fragment_end_y; i++){
		for (int j = fragment_start_x; j < fragment_end_x; j++) {
			if(fragmentbuffer[i][j].depth < framebuffer[i][j].depth){
				framebuffer[i][j].depth = fragmentbuffer[i][j].depth;
				framebuffer[i][j].r = fragmentbuffer[i][j].r;
				framebuffer[i][j].g = fragmentbuffer[i][j].g;
				framebuffer[i][j].b = fragmentbuffer[i][j].b;
				framebuffer[i][j].a = fragmentbuffer[i][j].a;
			}

			fragmentbuffer[i][j].depth = 3;
			fragmentbuffer[i][j].r = 0;
			fragmentbuffer[i][j].g = 0;
			fragmentbuffer[i][j].b = 0;
			fragmentbuffer[i][j].a = 0;
		}
	}
}


void displayOperation(){

	static unsigned long file_index = 0;

	unsigned long header_length = 54;
	unsigned char header[54];
    memset(header, 0, 54);

	unsigned long width = 640;
	unsigned long height = 400;

	unsigned long length = header_length + 3 * width * height;

    header[0] = 'B';
    header[1] = 'M';
    header[2] = length & 0xff;
    header[3] = (length >> 8) & 0xff;
    header[4] = (length >> 16) & 0xff;
    header[5] = (length >> 24) & 0xff;
    header[10] = header_length;
    header[14] = 40;
    header[18] = width & 0xff;
    header[19] = (width >> 8) & 0xff;
    header[20] = (width >> 16) & 0xff;
    header[22] = height & 0xff;
    header[23] = (height >> 8) & 0xff;
    header[24] = (height >> 16) & 0xff;
    header[26] = 1;
    header[28] = 24;
    header[34] = 16;
    header[36] = 0x13;
    header[37] = 0x0b;
    header[42] = 0x13;
    header[43] = 0x0b;

    char file_name[64];
    sprintf(file_name, "./%ul.bmp", file_index);
    FILE* f = fopen (file_name, "wb");
	if (!f) {
			perror ("fopen");
			return;
	}

    // Write header.
    if (header_length != fwrite (header, 1, header_length, f)) {
            perror ("fwrite");
            fclose (f);
            return;
    }

    // Write pixels
    // Note : BMP has lower rows first.
    for (int i=height-1; i >= 0; i--) {
            for (int j=0; j < width; j++) {
                    unsigned char rgba[4];
                    pixel pix = framebuffer[i][j];

                    rgba[0] = pix.b & 0xff;
                    rgba[1] = pix.g & 0xff;
                    rgba[2] = pix.r & 0xff;
		    
		    //  printf("i%d, j:%d rgba0:%d rgba1:%d rgba2:%d \n", i, j, rgba[0], rgba[1], rgba[2]); 

                    if (3 != fwrite (rgba, 1, 3, f)) {
                            perror ("fwrite");
                            fclose (f);
                            return;
                    }
            }
    }

    fclose (f);

    file_index = file_index + 1;

	for(int i = 0; i < 400; i++){
		for (int j=0; j < 640; j++) {
			framebuffer[i][j].depth = 3;
			framebuffer[i][j].r = 0;
			framebuffer[i][j].g = 0;
			framebuffer[i][j].b = 0;
			framebuffer[i][j].a = 0;
		}
	}

    return;
}

void framebufferOperation(bool is_endprimitive, bool is_draw){
	if(is_endprimitive){
	  zbufferOperation();  // in your design, no need to test z-buffer values 
	}

	if(is_draw){
		displayOperation();
	}
}


////////////////////////////////////////////////////////////////////////
// desc: Set g_condition_code_register depending on the values of val1 and val2
// hint: bit0 (N) is set only when val1 < val2
////////////////////////////////////////////////////////////////////////
void SetConditionCodeInt(const int16_t val1, const int16_t val2) 
{
 if (val1 < val2)
    g_condition_code_register.int_value = 0x01;
  else if (val1 == val2)
    g_condition_code_register.int_value = 0x02;
  else // (val1 > val2)
    g_condition_code_register.int_value = 0x04;
}

////////////////////////////////////////////////////////////////////////
// desc: Set g_condition_code_register depending on the values of val1 and val2
// hint: bit0 (N) is set only when val1 < val2
////////////////////////////////////////////////////////////////////////
void SetConditionCodeFloat(const float val1, const float val2) 
{

 if (val1 < val2)
    g_condition_code_register.int_value = 0x01;
  else if (val1 == val2)
    g_condition_code_register.int_value = 0x02;
  else // (val1 > val2)
    g_condition_code_register.int_value = 0x04;

}

////////////////////////////////////////////////////////////////////////
// Initialize global variables
////////////////////////////////////////////////////////////////////////
void InitializeGlobalVariables() 
{
  memset(&g_condition_code_register, 0x00, sizeof(ScalarRegister));
  memset(g_scalar_registers, 0x00, sizeof(ScalarRegister) * NUM_SCALAR_REGISTER);
  memset(g_vector_registers, 0x00, sizeof(VectorRegister) * NUM_VECTOR_REGISTER);
  memset(g_memory, 0x00, sizeof(unsigned char) * MEMORY_SIZE);
}

////////////////////////////////////////////////////////////////////////
// desc: Convert 16-bit 2's complement signed integer to 32-bit
////////////////////////////////////////////////////////////////////////
int SignExtension(const int16_t value) 
{
  return (value >> 15) == 0 ? value : ((0xFFFF << 16) | value);
}



  static const unsigned short offset_table[64] = { 
    0, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 
    0, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024 };

  

float DecodeBinaryToFloatingPointNumber(int value){

#define FIXED_TO_FLOAT187(n)( (float) (-1 * ((n >> 15) & 0x1) * (1<< 8)) + (float) (( n & (0x7fff)) /(float)(1 << 7)))
#define FLOAT_TO_FIXED187(n)  ((int)((n) * (float)(1<<(7)))) & 0xffff

  float out; 
  out = FIXED_TO_FLOAT187(value); 
  return out; 
}
//  float out;
// std::memcpy(&out, &bits, sizeof(float));
// return out;
//}

////////////////////////////////////////////////////////////////////////
// desc: Decode binary-encoded instruction and Parse into TraceOp structure
//       which we will use execute later
// input: 32-bit encoded instruction
// output: TraceOp structure filled with the information provided from the input
////////////////////////////////////////////////////////////////////////
TraceOp DecodeInstruction(const uint32_t instruction) 
{
  TraceOp ret_trace_op;
  memset(&ret_trace_op, 0x00, sizeof(ret_trace_op));

  uint8_t opcode = (instruction & 0xFF000000) >> 24;
  ret_trace_op.opcode = opcode;

  switch (opcode) {
    case OP_ADD_D: {
      int destination_register_idx = (instruction & 0x00F00000) >> 20;
      int source_register_1_idx = (instruction & 0x000F0000) >> 16;
      int source_register_2_idx = (instruction & 0x00000F00) >> 8;
      ret_trace_op.scalar_registers[0] = destination_register_idx;
      ret_trace_op.scalar_registers[1] = source_register_1_idx;
      ret_trace_op.scalar_registers[2] = source_register_2_idx;
    }
    break;

    case OP_ADDI_D: {
      int destination_register_idx = (instruction & 0x00F00000) >> 20;
      int source_register_idx_idx = (instruction & 0x000F0000) >> 16;
      int immediate_value = SignExtension(instruction & 0x0000FFFF);
      ret_trace_op.scalar_registers[0] = destination_register_idx;
      ret_trace_op.scalar_registers[1] = source_register_idx_idx;
      ret_trace_op.int_value = immediate_value;
    }
    break;

    case OP_ADD_F: {
      int destination_register_idx = (instruction & 0x00F00000) >> 20;
      int source_register_1_idx = (instruction & 0x000F0000) >> 16;
      int source_register_2_idx = (instruction & 0x00000F00) >> 8;
      ret_trace_op.scalar_registers[0] = destination_register_idx;
      ret_trace_op.scalar_registers[1] = source_register_1_idx;
      ret_trace_op.scalar_registers[2] = source_register_2_idx;

    }
    break;

    case OP_ADDI_F: {
      int destination_register_idx = (instruction & 0x00F00000) >> 20;
      int source_register_idx = (instruction & 0x000F0000) >> 16;
      float immediate_value = DecodeBinaryToFloatingPointNumber(instruction & 0x0000FFFF);
      ret_trace_op.scalar_registers[0] = destination_register_idx;
      ret_trace_op.scalar_registers[1] = source_register_idx;
      ret_trace_op.float_value = immediate_value;
      ret_trace_op.int_value = (int) immediate_value; 
    }
    break;

    case OP_VADD: {
      int destination_register_idx = (instruction & 0x003F0000) >> 16;
      int source_register_1_idx = (instruction & 0x00003F00) >> 8;
      int source_register_2_idx = (instruction & 0x0000003F);
      ret_trace_op.vector_registers[0] = destination_register_idx;
      ret_trace_op.vector_registers[1] = source_register_1_idx;
      ret_trace_op.vector_registers[2] = source_register_2_idx;
    }
    break;

    case OP_AND_D: {
       int destination_register_idx = (instruction & 0x00F00000) >> 20;
      int source_register_1_idx = (instruction & 0x000F0000) >> 16;
      int source_register_2_idx = (instruction & 0x00000F00) >> 8;
      ret_trace_op.scalar_registers[0] = destination_register_idx;
      ret_trace_op.scalar_registers[1] = source_register_1_idx;
      ret_trace_op.scalar_registers[2] = source_register_2_idx;
    }
    break;

    case OP_ANDI_D: {
       int destination_register_idx = (instruction & 0x00F00000) >> 20;
      int source_register_idx_idx = (instruction & 0x000F0000) >> 16;
      int immediate_value = SignExtension(instruction & 0x0000FFFF);
      ret_trace_op.scalar_registers[0] = destination_register_idx;
      ret_trace_op.scalar_registers[1] = source_register_idx_idx;
      ret_trace_op.int_value = immediate_value;
    }
    break;

    case OP_MOV: {
      int destination_register_idx = (instruction & 0x000F0000) >> 16;
      int source_register_idx = (instruction & 0x00000F00) >> 8;
      ret_trace_op.scalar_registers[0] = destination_register_idx;
      ret_trace_op.scalar_registers[1] = source_register_idx;
    }
    break;

    case OP_MOVI_D: {
         int destination_register_idx = (instruction & 0x000F0000) >> 16;
      int immediate_value = SignExtension(instruction & 0x0000FFFF);
      ret_trace_op.scalar_registers[0] = destination_register_idx;
      ret_trace_op.int_value = immediate_value;
    }
    break;

    case OP_MOVI_F: {
       int destination_register_idx = (instruction & 0x000F0000) >> 16;
      float immediate_value = DecodeBinaryToFloatingPointNumber(instruction & 0x0000FFFF);
      ret_trace_op.scalar_registers[0] = destination_register_idx;
      ret_trace_op.float_value = immediate_value;
    }
    break;

    case OP_VMOV: {
        int destination_register_idx = (instruction & 0x003F0000) >> 16;
      int source_register_idx = (instruction & 0x00003F00) >> 8;
      ret_trace_op.vector_registers[0] = destination_register_idx;
      ret_trace_op.vector_registers[1] = source_register_idx;
    
      
    }
    break;

    case OP_VMOVI: {
       int destination_register_idx = (instruction & 0x003F0000) >> 16;
      float immediate_value = DecodeBinaryToFloatingPointNumber(instruction & 0x0000FFFF);
      ret_trace_op.vector_registers[0] = destination_register_idx;
      ret_trace_op.float_value = immediate_value;


    }
    break;

    case OP_CMP: {
      int source_register_1_idx = (instruction & 0x000F0000) >> 16;
      int source_register_2_idx = (instruction & 0x00000F00) >> 8;
      ret_trace_op.scalar_registers[0] = source_register_1_idx;
      ret_trace_op.scalar_registers[1] = source_register_2_idx;
    }
    break;

    case OP_CMPI: {
       int source_register_idx = (instruction & 0x000F0000) >> 16;
      int immediate_value = SignExtension(instruction & 0x0000FFFF);
      ret_trace_op.scalar_registers[0] = source_register_idx;
      ret_trace_op.int_value = immediate_value;
    }
    break;

    case OP_VCOMPMOV: {
        int element_idx = (instruction & 0x00C00000) >> 22;
      int destination_register_idx = (instruction & 0x003F0000) >> 16;
      int source_register_idx = (instruction & 0x00000F00) >> 8;
      ret_trace_op.idx = element_idx;
      ret_trace_op.vector_registers[0] = destination_register_idx;
      ret_trace_op.scalar_registers[0] = source_register_idx;

    }
    break;

    case OP_VCOMPMOVI: {
        int element_idx = (instruction & 0x00C00000) >> 22;
      int destination_register_idx = (instruction & 0x003F0000) >> 16;
      float immediate_value = DecodeBinaryToFloatingPointNumber(instruction & 0x0000FFFF);
      ret_trace_op.idx = element_idx;
      ret_trace_op.vector_registers[0] = destination_register_idx;
      ret_trace_op.float_value = immediate_value;
      printf("op_vcompmov immediate :%d float:%f \n", (int) (instruction & 0x0000ffff), immediate_value); 
    }
    break;

    case OP_LDB:
    case OP_LDW: {
       int destination_register_idx = (instruction & 0x00F00000) >> 20;
      int base_register_idx = (instruction & 0x000F0000) >> 16;
      int offset = SignExtension((int16_t)(instruction & 0x0000FFFF));
      ret_trace_op.scalar_registers[0] = destination_register_idx;
      ret_trace_op.scalar_registers[1] = base_register_idx;
      ret_trace_op.int_value = offset;
    }
    break;

    case OP_STB:
    case OP_STW: {
      int source_register_idx = (instruction & 0x00F00000) >> 20;
      int base_register_idx = (instruction & 0x000F0000) >> 16;
      int offset = SignExtension((int16_t)(instruction & 0x0000FFFF));
      ret_trace_op.scalar_registers[0] = source_register_idx;
      ret_trace_op.scalar_registers[1] = base_register_idx;
      ret_trace_op.int_value = offset;

    }
    break;

    case OP_PUSHMATRIX: {   

   
    }
    break;

    case OP_POPMATRIX: {
      	
    }
    break;

    case OP_ENDPRIMITIVE: {
      
    }
    break;

    case OP_LOADIDENTITY: {
      	
    }
    break;

    case OP_FLUSH: {
    }
    break;

    case OP_DRAW: {
      
    }
    break;

    case OP_BEGINPRIMITIVE: {
       int primitive_type = (instruction & 0x000F0000) >> 16;
      ret_trace_op.primitive_type = primitive_type;
    }
    break;

    case OP_JMP:
    case OP_JSRR: {
       int base_register = (instruction & 0x000F0000) >> 16;
      ret_trace_op.scalar_registers[0] = base_register;
    }
    break;

    case OP_SETVERTEX: 
    case OP_SETCOLOR: 
    case OP_ROTATE: 
    case OP_TRANSLATE: 
    case OP_SCALE: {
      int vector_register_idx = (instruction & 0x003F0000) >> 16;
      ret_trace_op.vector_registers[0] = vector_register_idx;	
    }
    break;

    case OP_BRN: 
    case OP_BRZ:
    case OP_BRP:
    case OP_BRNZ:
    case OP_BRNP:
    case OP_BRZP:
    case OP_BRNZP:
    case OP_JSR: {
      int pc_offset = SignExtension((int16_t)(instruction & 0x0000FFFF));
      ret_trace_op.int_value = pc_offset;
    }
    break;

    default:
    break;
  }

  return ret_trace_op;
}

////////////////////////////////////////////////////////////////////////
// desc: Execute the behavior of the instruction (Simulate)
// input: Instruction to execute 
// output: Non-branch operation ? -1 : OTHER (PC-relative or absolute address)
////////////////////////////////////////////////////////////////////////
int ExecuteInstruction(const TraceOp &trace_op) 
{
  int ret_next_instruction_idx = -1;

  uint8_t opcode = trace_op.opcode;
  switch (opcode) {
    case OP_ADD_D: {
      int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
      int source_value_2 = g_scalar_registers[trace_op.scalar_registers[2]].int_value;
      g_scalar_registers[trace_op.scalar_registers[0]].int_value = 
        source_value_1 + source_value_2;
      SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
    }
    break;

    case OP_ADDI_D: {
      int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
      int source_value_2 = trace_op.int_value;
      g_scalar_registers[trace_op.scalar_registers[0]].int_value = 
        source_value_1 + source_value_2;
      SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
    }
    break;

    
    case OP_ADD_F: {
      float source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].float_value;
      float source_value_2 = g_scalar_registers[trace_op.scalar_registers[2]].float_value;
      g_scalar_registers[trace_op.scalar_registers[0]].float_value = 
        source_value_1 + source_value_2;
      SetConditionCodeFloat(g_scalar_registers[trace_op.scalar_registers[0]].float_value, 0.0f);
    }
    break;

    case OP_ADDI_F: {
      float source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].float_value;
      float source_value_2 = trace_op.float_value;
      g_scalar_registers[trace_op.scalar_registers[0]].float_value = 
        source_value_1 + source_value_2;
      SetConditionCodeFloat(g_scalar_registers[trace_op.scalar_registers[0]].float_value, 0.0f);
    }
    break;

    case OP_VADD: {
      for (int i = 0; i < NUM_VECTOR_ELEMENTS; i++)
        g_vector_registers[trace_op.vector_registers[0]].element[i].float_value = 
          g_vector_registers[trace_op.vector_registers[1]].element[i].float_value +
          g_vector_registers[trace_op.vector_registers[2]].element[i].float_value;
    }
    break;

    case OP_AND_D: {
      int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
      int source_value_2 = g_scalar_registers[trace_op.scalar_registers[2]].int_value;
      g_scalar_registers[trace_op.scalar_registers[0]].int_value = 
        source_value_1 & source_value_2;
      SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
    }
    break;

    case OP_ANDI_D: {
      int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
      int source_value_2 = trace_op.int_value;
      g_scalar_registers[trace_op.scalar_registers[0]].int_value = 
        source_value_1 & source_value_2;
      SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
    }
    break;

    case OP_MOV: {
      if (trace_op.scalar_registers[0] < 7) {
        g_scalar_registers[trace_op.scalar_registers[0]].int_value = 
          g_scalar_registers[trace_op.scalar_registers[1]].int_value;
        SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
      } else if (trace_op.scalar_registers[0] > 7) {
        g_scalar_registers[trace_op.scalar_registers[0]].float_value = 
          g_scalar_registers[trace_op.scalar_registers[1]].float_value;
        SetConditionCodeFloat(g_scalar_registers[trace_op.scalar_registers[0]].float_value, 0.0f);
      }
    }
    break;

    case OP_MOVI_D: {
      g_scalar_registers[trace_op.scalar_registers[0]].int_value = trace_op.int_value;
      SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
    }
    break;

    case OP_MOVI_F: {
      g_scalar_registers[trace_op.scalar_registers[0]].float_value = trace_op.float_value;
      SetConditionCodeFloat(g_scalar_registers[trace_op.scalar_registers[0]].float_value, 0.0f);
    }
    break;

    case OP_VMOV: {
      for (int i = 0; i < NUM_VECTOR_ELEMENTS; i++) {
        g_vector_registers[trace_op.vector_registers[0]].element[i].float_value =
          g_vector_registers[trace_op.vector_registers[1]].element[i].float_value;
      }
    }
    break;

    case OP_VMOVI: {
      for (int i = 0; i < NUM_VECTOR_ELEMENTS; i++)
        g_vector_registers[trace_op.vector_registers[0]].element[i].float_value = 
          trace_op.float_value;
    }
    break;

    case OP_CMP: {
      if (trace_op.scalar_registers[0] < 7)
        SetConditionCodeInt(
          g_scalar_registers[trace_op.scalar_registers[0]].int_value,
          g_scalar_registers[trace_op.scalar_registers[1]].int_value);
      else if (trace_op.scalar_registers[0] > 7)
        SetConditionCodeFloat(
          g_scalar_registers[trace_op.scalar_registers[0]].float_value,
          g_scalar_registers[trace_op.scalar_registers[1]].float_value);
    }
    break;

    case OP_CMPI: {
      if (trace_op.scalar_registers[0] < 7)
        SetConditionCodeInt(
          g_scalar_registers[trace_op.scalar_registers[0]].int_value,
          trace_op.int_value);
      else if (trace_op.scalar_registers[0] > 7)
        SetConditionCodeFloat(
          g_scalar_registers[trace_op.scalar_registers[0]].float_value,
          trace_op.float_value);
    }
    break;

    case OP_VCOMPMOV: {
      int idx = trace_op.idx;
      g_vector_registers[trace_op.vector_registers[0]].element[idx].float_value =
        g_scalar_registers[trace_op.scalar_registers[0]].float_value;
    }
    break;

    case OP_VCOMPMOVI: {
      int idx = trace_op.idx;
      g_vector_registers[trace_op.vector_registers[0]].element[idx].float_value =
        trace_op.float_value;
    }
    break;

    case OP_LDB: {
      int address = g_scalar_registers[trace_op.scalar_registers[1]].int_value 
        + trace_op.int_value;
      memcpy(&g_scalar_registers[trace_op.scalar_registers[0]],
        &g_memory[address], sizeof(int8_t));
    }
    break;

    case OP_LDW: {
      int address = g_scalar_registers[trace_op.scalar_registers[1]].int_value
        + trace_op.int_value;
      memcpy(&g_scalar_registers[trace_op.scalar_registers[0]],
        &g_memory[address], sizeof(int16_t));
    }
    break;

    case OP_STB: {
      int address = g_scalar_registers[trace_op.scalar_registers[1]].int_value
        + trace_op.int_value;
      memcpy(&g_memory[address],
        &g_scalar_registers[trace_op.scalar_registers[0]], sizeof(int8_t));
    }
    break;

    case OP_STW: {
      int address = g_scalar_registers[trace_op.scalar_registers[1]].int_value
        + trace_op.int_value;
      memcpy(&g_memory[address], 
        &g_scalar_registers[trace_op.scalar_registers[0]], sizeof(int16_t));
    }
    break;


    case OP_PUSHMATRIX: {
	pushmatrix();
    }
    break;

    case OP_POPMATRIX: {
      popmatrix();
    }
    break;

    case OP_ENDPRIMITIVE: {
      	is_endprimitive = true;
    }
    break;

    case OP_LOADIDENTITY: {
      loadidentity();
    }
    break;

    case OP_FLUSH: {

    }
    break;

    case OP_DRAW: {
          	is_draw = true;
    }  
    break;

    case OP_BEGINPRIMITIVE: {
	is_startprimitive = true;
    }
    break;

    case OP_JMP: {
      if (g_scalar_registers[trace_op.scalar_registers[0]].int_value == 0x07) // OP_RET
        ret_next_instruction_idx = g_scalar_registers[LR_IDX].int_value;
      else // OP_JMP
        ret_next_instruction_idx = g_scalar_registers[trace_op.scalar_registers[0]].int_value;
    }
    break;

    case OP_JSRR: {
      ret_next_instruction_idx = g_scalar_registers[trace_op.scalar_registers[0]].int_value;
    }
      break;

    case OP_SETVERTEX: {

	is_setvertex = true;

		float x_value =
			g_vector_registers[(trace_op.vector_registers[0])].element[1].float_value;
		float y_value =
			g_vector_registers[(trace_op.vector_registers[0])].element[2].float_value;
		float z_value =
			g_vector_registers[(trace_op.vector_registers[0])].element[3].float_value;
		setvertex(x_value, y_value, z_value);
#ifdef GRAPH_DEBUG 
		printf("set vertex x:%f y:%f z:%f \n", x_value, y_value, z_value); 
#endif 

    }
    break;

    case OP_SETCOLOR: {
      int r_value =	(int) g_vector_registers[(trace_op.vector_registers[0])].element[0].float_value;
		int g_value =
		  (int) g_vector_registers[(trace_op.vector_registers[0])].element[1].float_value;
		int b_value =
		  (int) g_vector_registers[(trace_op.vector_registers[0])].element[2].float_value;
		color(r_value, g_value, b_value);
#ifdef GRAPH_DEBUG 
		printf("set color: r:%d  g:%d b:%d \n", r_value, g_value, b_value); 
#endif 

    }
    break;

    case OP_ROTATE: {
float angle =
				g_vector_registers[(trace_op.vector_registers[0])].element[0].float_value;
		float z_value =
				g_vector_registers[(trace_op.vector_registers[0])].element[3].float_value;
		rotate(angle, z_value); // we multify 2 to cover 360 degress 

    }
    break;

    case OP_TRANSLATE: {
	float x_value =
				g_vector_registers[(trace_op.vector_registers[0])].element[1].float_value;
		float y_value =
				g_vector_registers[(trace_op.vector_registers[0])].element[2].float_value;
		translate(x_value, y_value);

    }
    break;

    case OP_SCALE: {
float x_value =
				g_vector_registers[(trace_op.vector_registers[0])].element[1].float_value;
		float y_value =
				g_vector_registers[(trace_op.vector_registers[0])].element[2].float_value;
		scale(x_value, y_value);
    }
    break;

     case OP_BRN: {
      if (g_condition_code_register.int_value == 0x01)
        ret_next_instruction_idx = trace_op.int_value;
    }
    break;

    case OP_BRZ: {
      if (g_condition_code_register.int_value == 0x02)
        ret_next_instruction_idx = trace_op.int_value;
    }
    break;

    case OP_BRP: {
      if (g_condition_code_register.int_value == 0x04)
        ret_next_instruction_idx = trace_op.int_value;
    }
    break;

    case OP_BRNZ: {
      if (g_condition_code_register.int_value == 0x03)
        ret_next_instruction_idx = trace_op.int_value;
    }
    break;

    case OP_BRNP: {
      if (g_condition_code_register.int_value == 0x05)
        ret_next_instruction_idx = trace_op.int_value;
    }
    break;

    case OP_BRZP: {
      if (g_condition_code_register.int_value == 0x06)
        ret_next_instruction_idx = trace_op.int_value;
    }
    break;

    case OP_BRNZP: {
      if (g_condition_code_register.int_value == 0x07)
        ret_next_instruction_idx = trace_op.int_value;
    }
    break;

    case OP_JSR: {
      ret_next_instruction_idx = trace_op.int_value;
    }
    break;

    default:
    break;
  }

  return ret_next_instruction_idx;
}

////////////////////////////////////////////////////////////////////////
// desc: Dump given trace_op
////////////////////////////////////////////////////////////////////////
void PrintTraceOp(const TraceOp &trace_op) 
{  
  cout << "  opcode: " << SignExtension(trace_op.opcode);
  cout << ", scalar_register[0]: " << (int) trace_op.scalar_registers[0];
  cout << ", scalar_register[1]: " << (int) trace_op.scalar_registers[1];
  cout << ", scalar_register[2]: " << (int) trace_op.scalar_registers[2];
  cout << ", vector_register[0]: " << (int) trace_op.vector_registers[0];
  cout << ", vector_register[1]: " << (int) trace_op.vector_registers[1];
  cout << ", idx: " << (int) trace_op.idx;
  cout << ", primitive_index: " << (int) trace_op.primitive_type;
  cout << ", int_value: " << (int) trace_op.int_value;
  cout << ", float_value: " << (float) trace_op.float_value << endl;
}

////////////////////////////////////////////////////////////////////////
// desc: This function is called every trace is executed
//       to provide the contents of all the registers
////////////////////////////////////////////////////////////////////////
void PrintContext(const TraceOp &current_op)
{
  cout << "--------------------------------------------------" << endl;
  cout << "Instruction Count: " << g_instruction_count
       << ", Current Instruction's Opcode: " << current_op.opcode
       << ", Next Instruction's Opcode: " << g_trace_ops[g_scalar_registers[PC_IDX].int_value].opcode 
       << endl;
  for (int srIdx = 0; srIdx < NUM_SCALAR_REGISTER; srIdx++) {
    cout << "R" << srIdx << ":" 
         << ((srIdx < 8 || srIdx == 15) ? g_scalar_registers[srIdx].int_value : g_scalar_registers[srIdx].float_value) 
         << (srIdx == NUM_SCALAR_REGISTER-1 ? "" : ", ");
  }
  cout << endl;
  for (int vrIdx = 0; vrIdx < NUM_VECTOR_REGISTER; vrIdx++) {
    cout << "V" << vrIdx << ":";
    for (int elmtIdx = 0; elmtIdx < NUM_VECTOR_ELEMENTS; elmtIdx++) { 
      cout << "Element[" << elmtIdx << "] = " 
           << g_vector_registers[vrIdx].element[elmtIdx].float_value 
           << (elmtIdx == NUM_VECTOR_ELEMENTS-1 ? "" : ",");
    }
    cout << endl;
  }
  cout << endl;
  cout << "--------------------------------------------------" << endl;
}

int main(int argc, char **argv) 
{
  ///////////////////////////////////////////////////////////////
  //  Global Variables
  ///////////////////////////////////////////////////////////////
  //
  InitializeGlobalVariables();
  InitializeGPUVariables(); 

  ///////////////////////////////////////////////////////////////
  // Load Program
  ///////////////////////////////////////////////////////////////
  //
  if (argc != 2) {
    cerr << "Usage: " << argv[0] << " <input>" << endl;
    return 1;
  }

  ifstream infile(argv[1]);
  if (!infile) {
    cerr << "Error: Failed to open input file " << argv[1] << endl;
    return 1;
  }

  vector< bitset<sizeof(uint32_t)*CHAR_BIT> > instructions;
  while (!infile.eof()) {
    bitset<sizeof(uint32_t)*CHAR_BIT> bits;
    infile >> bits;
    if (infile.eof())  break;
    instructions.push_back(bits);
  }
  
  infile.close();

#ifdef DEBUG
  cout << "The contents of the instruction vectors are :" << endl;
  for (vector< bitset<sizeof(uint32_t)*CHAR_BIT> >::iterator ii =
      instructions.begin(); ii != instructions.end(); ii++) {
    cout << "  " << *ii << endl;
  }
#endif // DEBUG

  ///////////////////////////////////////////////////////////////
  // Decode instructions into g_trace_ops
  ///////////////////////////////////////////////////////////////
  //
  for (vector< bitset<sizeof(uint32_t)*CHAR_BIT> >::iterator ii =
      instructions.begin(); ii != instructions.end(); ii++) {
    uint32_t inst = (uint32_t) ((*ii).to_ulong());
    TraceOp trace_op = DecodeInstruction(inst);
    g_trace_ops.push_back(trace_op);
  }

#ifdef DEBUG
  cout << "The contents of the g_trace_ops vectors are :" << endl;
  for (vector<TraceOp>::iterator ii = g_trace_ops.begin();
      ii != g_trace_ops.end(); ii++) {
    PrintTraceOp(*ii);
  }
#endif // DEBUG

  ///////////////////////////////////////////////////////////////
  // Execute 
  ///////////////////////////////////////////////////////////////
  //
  g_scalar_registers[PC_IDX].int_value = 0;
  for (;;) {
    TraceOp current_op = g_trace_ops[g_scalar_registers[PC_IDX].int_value];
    int idx = ExecuteInstruction(current_op);
    
    if (current_op.opcode == OP_JSR || current_op.opcode == OP_JSRR)
      g_scalar_registers[LR_IDX].int_value = g_scalar_registers[PC_IDX].int_value + 1;


    
    g_scalar_registers[PC_IDX].int_value += 1; 
    if (idx != -1) { // Branch
      if (current_op.opcode == OP_JMP || current_op.opcode == OP_JSRR) // Absolote addressing
        g_scalar_registers[PC_IDX].int_value = idx; 
      else // PC-relative addressing (OP_JSR || OP_BRXXX)
        g_scalar_registers[PC_IDX].int_value += idx; 
    }


      //vertexAssembly();
      vertexOperation(is_setvertex);
      primitiveAssembly(is_startprimitive, is_setvertex);
      //primitiveOperation();
      rasterationOperation(is_endprimitive);
      //fragmentOperation();
	framebufferOperation(is_endprimitive, is_draw);

#ifdef DEBUG
    g_instruction_count++;
    // PrintContext(current_op);
#endif // DEBUG

    // End of the program
    if (g_scalar_registers[PC_IDX].int_value == g_trace_ops.size())
      break;

    is_setvertex = false; 
    is_startprimitive = false;
    is_endprimitive = false; 
    is_draw = false; 
  }

  return 0;
}

