#define _CRT_SECURE_NO_WARNINGS

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdbool.h>

#define PI (3.141592653589793)
#define DEG_TO_RAD(x) ((x)*PI/180.0)

__declspec(dllexport) void __cdecl ipa_algorithm_c(unsigned char *, unsigned char *, unsigned int, unsigned int, int, char**);

typedef struct vec2_t {
    float u, v;
} vec2;

typedef struct vec2i_t {
    int u, v;
} vec2i;

typedef struct vec3_t {
    float x, y, z;
} vec3;

typedef struct options_t {
    float angle;
    float scale;
    vec2 pivot;
}options;

typedef float mat2[4];
typedef float mat2x3[6];

vec2 mat2_mul_vec2(vec2 vec, mat2 mat);

void fill_coords(vec2 *coords, unsigned int width, unsigned int height);
void translate_coords(vec2 *coords, vec2 pivot, unsigned int width, unsigned int height);
void transform_coords(vec2 *coords, mat2 matrix, unsigned int width, unsigned int height);
void transform_coords_avx2(vec2 *coords_64byte_align, mat2 matrix, unsigned int count);
void transform_coords_avx2_fma(vec2 *coords_64byte_align, mat2x3 matrix, unsigned int count);

void display_coords(vec2 *coords, unsigned char *output_data, unsigned int width, unsigned int height);
void transform_image_no_aa(vec2 *coords, unsigned char *input_data, unsigned char *output_data, unsigned int width, unsigned int height);
void transform_image_bilinear(vec2 *coords, unsigned char *input_data, unsigned char *output_data, unsigned int width, unsigned int height);

bool load_args(int argc, char **argv, options *args){
    /*
    *   -a -angle ANGLE_DEGREES
    *   -s -scale SCALE
    *   -p -pivot PIVOT_X PIVOT_Y       note: range <0,1>
    */

    // starting from argument #2, ignoring executable path and image input
    for (int i = 2; i < argc; i++) {
        if (strcmp("-a", argv[i]) == 0 || strcmp("-angle", argv[i]) == 0) {
            i++; if (i >= argc) { return false; }
            if (sscanf(argv[i], "%f", &args->angle) != 1) {
                return false;
            }
        }
        else if (strcmp("-s", argv[i]) == 0 || strcmp("-scale", argv[i]) == 0) {
            i++; if (i >= argc) { return false; }
            if (sscanf(argv[i], "%f", &args->scale) != 1) {
                return false;
            }
        }
        else if (strcmp("-p", argv[i]) == 0 || strcmp("-pivot", argv[i]) == 0) {
            i++; if (i >= argc) { return false; }
            if (sscanf(argv[i], "%f", &args->pivot.u) != 1) {
                return false;
            }
            i++; if (i >= argc) { return false; }
            if (sscanf(argv[i], "%f", &args->pivot.v) != 1) {
                return false;
            }
        }
        else {
            return false;
        }
    }
    return true;
}

void ipa_algorithm_c(unsigned char *input_data, unsigned char *output_data, unsigned int width, unsigned int height, int argc, char** argv)
{
    //defaults
    options arg = { .scale = 1.0f,
                    .angle = 0.0f,
                    .pivot = {.u = 0.5f,.v = 0.5f}  };

    if (!load_args(argc, argv, &arg)) { 
        fprintf(stderr, "Warning: wrong arguments!\n\n");
        printf("Usage: display_image ImageToLoadAndDisplay [-a|-angle ANGLE_DEGREES] [-s|-scale SCALE] [-p|-pivot PIVOT_X PIVOT_Y]\n\n");
        return;
    }

    float angle_rad = (float)DEG_TO_RAD(arg.angle);
    vec2 scale = { .u = arg.scale,.v = arg.scale };
    vec2 pivot = { .u = arg.pivot.u * width,.v = arg.pivot.v * height };

	float a = cosf(angle_rad) / scale.u;
	float b = sinf(angle_rad) / scale.v;
	float c = -sinf(angle_rad) / scale.u;
	float d = cosf(angle_rad) / scale.v;
	float u = pivot.u;
	float v = pivot.v;
	mat2x3 transform_matrix_inv = { a, b, u - a*u - b*v, c, d, -c*u + v - d*v };

	unsigned int count = width * height;
	//TODO: count % 4 == 0
	vec2 *coords = _aligned_malloc(sizeof(vec2)*count, 64);

    fill_coords(coords, width, height);

	transform_coords_avx2_fma(coords, transform_matrix_inv, width * height);

    //display_coords(coords, output_data, width, height);
    //transform_image_no_aa(coords, input_data, output_data, width, height);
    transform_image_bilinear(coords, input_data, output_data, width, height);

	_aligned_free(coords);
}

void transform_image_bilinear(vec2 *coords, unsigned char *input_data, unsigned char *output_data, unsigned int width, unsigned int height) {
    for (unsigned int y = 0; y < height; y++) {
        for (unsigned int x = 0; x < width; x++)
        {
            unsigned int id = y*width + x;

            vec3 col = { 0.0f, 0.0f ,0.0f };

            vec2i coord[4] = {  {.u = (int)coords[id].u,     .v = (int)coords[id].v },
                                {.u = (int)coords[id].u + 1, .v = (int)coords[id].v },
                                {.u = (int)coords[id].u,     .v = (int)coords[id].v + 1 },
                                {.u = (int)coords[id].u + 1, .v = (int)coords[id].v + 1 } };

            vec2 d = {  .u = coords[id].u - (float)((int)coords[id].u),
                        .v = coords[id].v - (float)((int)coords[id].v)  };
            

            float perc[4] = { (1.0f - d.u)*(1.0f - d.v), d.u*(1.0f - d.v) ,(1.0f - d.u)*d.v ,d.u*d.v };

            for (int i = 0; i < 4; i++) {
                if (coord[i].u > 0 && coord[i].u < (int)width && coord[i].v>0 && coord[i].v < (int)height) {
                    unsigned int transformed_idx = 3 * (coord[i].v*width + coord[i].u);
                    col.x += input_data[transformed_idx + 0] * perc[i];
                    col.y += input_data[transformed_idx + 1] * perc[i];
                    col.z += input_data[transformed_idx + 2] * perc[i];
                }
            }
            col.x = col.x < 0 ? 0 : col.x > 255 ? 255 : col.x;
            col.y = col.y < 0 ? 0 : col.y > 255 ? 255 : col.y;
            col.z = col.z < 0 ? 0 : col.z > 255 ? 255 : col.z;

            unsigned int idx = 3 * id;
            output_data[idx + 0] = (unsigned char)col.x;    //B
            output_data[idx + 1] = (unsigned char)col.y;    //G
            output_data[idx + 2] = (unsigned char)col.z;    //R
        }
    }
}

void transform_image_no_aa(vec2 *coords, unsigned char *input_data, unsigned char *output_data, unsigned int width, unsigned int height) {
    for (unsigned int y = 0; y < height; y++) {
        for (unsigned int x = 0; x < width; x++) {
            unsigned int id = y*width + x;
            vec2 coord = coords[id];
            unsigned int idx = 3 * id;
            if (coord.u > 0 && coord.u < width && coord.v>0 && coord.v < height) {
                unsigned int transformed_idx = 3 * (((unsigned int)coord.v)*width + ((unsigned int)coord.u));
                output_data[idx + 0] = input_data[transformed_idx + 0];    //B
                output_data[idx + 1] = input_data[transformed_idx + 1];    //G
                output_data[idx + 2] = input_data[transformed_idx + 2];    //R
            }
            else { //out of range
                output_data[idx + 0] = 0;    //B
                output_data[idx + 1] = 0;    //G
                output_data[idx + 2] = 0;    //R
            }
        }
    }
}

vec2 mat2_mul_vec2(vec2 vec, mat2 mat) {
    vec2 tmp;
    tmp.u = mat[0] * vec.u + mat[1] * vec.v;
    tmp.v = mat[2] * vec.u + mat[3] * vec.v;
    return tmp;
}

void transform_coords(vec2 *coords, mat2 matrix, unsigned int width, unsigned int height) {
    for (unsigned int y = 0; y < height; y++) {
        for (unsigned int x = 0; x < width; x++) {
            unsigned int idx = y*width + x;
            coords[idx] = mat2_mul_vec2(coords[idx], matrix);
        }
    }
}

void transform_coords_avx2(vec2 *coords_64byte_align, mat2 matrix, unsigned int count) {
	// +- 3 cycles per 1 vector transformation
	__asm {
		mov eax, matrix
		vbroadcastf128 ymm0, [eax]
		vpermilps ymm6, ymm0, 0x44 ;//0b01000100
		vpermilps ymm7, ymm0, 0xEE ;//0b11101110

		mov ecx, count
		shr ecx, 2 ;// divide our count by 4 (we are processing 4x2 floats)
		mov eax, coords_64byte_align

	l_loop0:
		test ecx, ecx
		jz l_break0

		vmovaps ymm0, [eax]
		vmulps ymm1, ymm0, ymm7
		vmulps ymm0, ymm0, ymm6

		vblendps ymm2, ymm0, ymm1, 0xAA ;//0b10101010
		vblendps ymm1, ymm0, ymm1, 0x55 ;//0b01010101
		vpermilps ymm1, ymm1, 0xB1 ;//0b10110001

		vaddps ymm0, ymm1, ymm2
		vmovaps [eax], ymm0

		add eax, 32
		dec ecx
		jmp l_loop0
	l_break0:
	}
}

void transform_coords_avx2_fma(vec2 * coords_64byte_align, mat2x3 matrix, unsigned int count)
{
	// Execute: coords[i] = vec2( mat2x3 matrix * vec3(vec2 coords[i], 1) )
	// +- 2.3 cycles per 1 vector transformation (average of multiple measurements)

	/*	Execution:
	*	ymm1 = m4, m0, m4, m0, m4, m0, m4, m0
	*	ymm2 = m5, m2, m5, m2, m5, m2, m5, m2
	*	ymm3 = m3, m1, m3, m1, m3, m1, m3, m1
	*	
	*	while(i < count) {
	*		ymm0 = v(3+i), u(3+i), v(2+i), u(2+i), v(1+i), u(1+i), v(0+i), u(0+i);
	*	4X:	coords[i] = vec2( mat2x3 matrix * vec3(vec2 coords[i], 1) );
	*		i += 4;
	*	}
	*/

	__asm {
		;// load matrix to ymm1, ymm2, ymm3
		mov eax, matrix
		vbroadcastss ymm0, [eax + 0 * 4];
		vbroadcastss ymm1, [eax + 4 * 4];
		vblendps ymm1, ymm0, ymm1, 0xAA;//0b10101010
		vbroadcastss ymm0, [eax + 2 * 4];
		vbroadcastss ymm2, [eax + 5 * 4];
		vblendps ymm2, ymm0, ymm2, 0xAA;//0b10101010
		vbroadcastss ymm0, [eax + 1 * 4];
		vbroadcastss ymm3, [eax + 3 * 4];
		vblendps ymm3, ymm0, ymm3, 0xAA;//0b10101010
		
		;// load &coords[0] to eax
		mov eax, coords_64byte_align;

		;// load end pointer to ecx
		mov ecx, count ;// move count to ecx
		and ecx, 0xfffffffc ;//TODO: check if divisible by 4
		shl ecx, 3 ;// multiply ecx by sizeof(vec2) == 8
		add ecx, eax

	l_loop1:
		cmp eax, ecx
		je l_break1

		vmovaps ymm0, [eax]

		vmovaps ymm4, ymm1
		vfmadd213ps ymm4, ymm0, ymm2
		vpermilps ymm0, ymm0, 0xB1 ;//0b10110001
		vfmadd213ps ymm0, ymm3, ymm4

		vmovaps [eax], ymm0

		add eax, 32
		jmp l_loop1
	l_break1:
	}
}

void translate_coords(vec2 *coords, vec2 pivot, unsigned int width, unsigned int height) {
    for (unsigned int y = 0; y < height; y++) {
        for (unsigned int x = 0; x < width; x++) {
            unsigned int idx = y*width + x;
            coords[idx].u += pivot.u;
            coords[idx].v += pivot.v;
        }
    }
}

void fill_coords(vec2 *coords, unsigned int width, unsigned int height) 
{
    for (unsigned int y = 0; y < height; y++) {
        for (unsigned int x = 0; x < width; x++) {
            unsigned int idx = y*width + x;
            coords[idx].u = (float)x;
            coords[idx].v = (float)y;
        }
    }
}

void display_coords(vec2 *coords, unsigned char *output_data, unsigned int width, unsigned int height) 
{
    // Transform coords for display
    for (unsigned int y = 0; y < height; y++) {
        for (unsigned int x = 0; x < width; x++) {
            unsigned int idx = y*width + x;
            // normalize
            coords[idx].u = coords[idx].u / width;
            coords[idx].v = coords[idx].v / height;
            // clamp
            coords[idx].u = coords[idx].u < 0 ? 0 : coords[idx].u;
            coords[idx].v = coords[idx].v < 0 ? 0 : coords[idx].v;
            // gamma correction
            //coords[idx].u *= coords[idx].u;
            //coords[idx].v *= coords[idx].v;
            // convert to 0-255 range
            coords[idx].u *= 255;
            coords[idx].v *= 255;
        }
    }

    // Display coords to output image
    for (unsigned int y = 0; y < height; y++) {
        for (unsigned int x = 0; x < width; x++) {
            unsigned int idx = 3 * (y*width + x);
            unsigned int c_idx = y*width + x;
            output_data[idx + 0] = 0;     //B
            output_data[idx + 1] = (unsigned char)coords[c_idx].v;     //G
            output_data[idx + 2] = (unsigned char)coords[c_idx].u;     //R
        }
    }
}