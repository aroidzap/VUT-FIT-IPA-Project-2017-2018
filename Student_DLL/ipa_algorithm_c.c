#include <stdlib.h>
#include <math.h>
#define PI (3.141592653589793)
#define DEG_TO_RAD(x) ((x)*PI/180.0)

__declspec(dllexport) void __cdecl ipa_algorithm_c(unsigned char *, unsigned char *, unsigned int, unsigned int, int, char**);

typedef struct vec2_t {
    float u, v;
} vec2;

typedef float mat2[4];

vec2 mat2_mul_vec2(vec2 vec, mat2 mat);

void fill_coords(vec2 *coords, unsigned int width, unsigned int height);
void translate_coords(vec2 *coords, vec2 pivot, unsigned int width, unsigned int height);
void scale_coords(vec2 *coords, vec2 scale, unsigned int width, unsigned int height);
void rotate_coords(vec2 *coords, mat2 rotation_matrix, unsigned int width, unsigned int height);

void display_coords(vec2 *coords, unsigned char *output_data, unsigned int width, unsigned int height);
void transform_image_no_aa(vec2 *coords, unsigned char *input_data, unsigned char *output_data, unsigned int width, unsigned int height);


void ipa_algorithm_c(unsigned char *input_data, unsigned char *output_data, unsigned int width, unsigned int height, int argc, char** argv)
{
    float angle = (float) DEG_TO_RAD(45.0);
    vec2 tmp, pivot = { .u = width / 2.0f,.v = height / 2.0f };
    mat2 rot_matrix_inv = { cosf(angle), sinf(angle), -sinf(angle), cosf(angle) };

    vec2 *coords = malloc(sizeof(vec2)*width*height);

    fill_coords(coords, width, height);

    tmp.u = -pivot.u; tmp.v = -pivot.v;
    translate_coords(coords, tmp, width, height);

    rotate_coords(coords, rot_matrix_inv, width, height);

    tmp.u = +pivot.u; tmp.v = +pivot.v;
    translate_coords(coords, tmp, width, height);

    //display_coords(coords, output_data, width, height);
    transform_image_no_aa(coords, input_data, output_data, width, height);

    free(coords);
}

void transform_image_no_aa(vec2 *coords, unsigned char *input_data, unsigned char *output_data, unsigned int width, unsigned int height) {
    for (unsigned int y = 0; y < height; y++) {
        for (unsigned int x = 0; x < width; x++) {
            unsigned int idx = 3 * (y*width + x);
            unsigned int coord_idx = y*width + x;
            unsigned int transformed_idx = 3 * ((unsigned int)(coords[coord_idx].v*width + coords[coord_idx].u));
            if (transformed_idx < width*height * 3) {
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

void rotate_coords(vec2 *coords, mat2 rotation_matrix, unsigned int width, unsigned int height) {
    for (unsigned int y = 0; y < height; y++) {
        for (unsigned int x = 0; x < width; x++) {
            unsigned int idx = y*width + x;
            coords[idx] = mat2_mul_vec2(coords[idx], rotation_matrix);
        }
    }
}

void scale_coords(vec2 *coords, vec2 scale, unsigned int width, unsigned int height) {
    for (unsigned int y = 0; y < height; y++) {
        for (unsigned int x = 0; x < width; x++) {
            unsigned int idx = y*width + x;
            coords[idx].u *= scale.u;
            coords[idx].v *= scale.v;
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