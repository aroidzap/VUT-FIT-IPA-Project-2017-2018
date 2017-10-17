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

typedef struct options_t {
    float angle;
    float scale;
    vec2 pivot;
}options;

typedef float mat2[4];

vec2 mat2_mul_vec2(vec2 vec, mat2 mat);

void fill_coords(vec2 *coords, unsigned int width, unsigned int height);
void translate_coords(vec2 *coords, vec2 pivot, unsigned int width, unsigned int height);
void transform_coords(vec2 *coords, mat2 matrix, unsigned int width, unsigned int height);

void display_coords(vec2 *coords, unsigned char *output_data, unsigned int width, unsigned int height);
void transform_image_no_aa(vec2 *coords, unsigned char *input_data, unsigned char *output_data, unsigned int width, unsigned int height);

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
    vec2 tmp, pivot = { .u = arg.pivot.u * width,.v = arg.pivot.v * height };
    mat2 rot_scale_matrix_inv = { cosf(angle_rad) / scale.u, sinf(angle_rad), -sinf(angle_rad), cosf(angle_rad) / scale.v };

    vec2 *coords = malloc(sizeof(vec2)*width*height);

    fill_coords(coords, width, height);

    tmp.u = -pivot.u; tmp.v = -pivot.v;
    translate_coords(coords, tmp, width, height);

    transform_coords(coords, rot_scale_matrix_inv, width, height);

    tmp.u = +pivot.u; tmp.v = +pivot.v;
    translate_coords(coords, tmp, width, height);

    //display_coords(coords, output_data, width, height);
    transform_image_no_aa(coords, input_data, output_data, width, height);

    free(coords);
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