__declspec(dllexport) void __cdecl ipa_algorithm_c(unsigned char *, unsigned char *, unsigned int, unsigned int, int, char**);

void ipa_algorithm_c(unsigned char *input_data, unsigned char *output_data, unsigned int width, unsigned int height, int argc, char** argv) {
    for (unsigned int y = 0; y < height; y++) {
        for (unsigned int x = 0; x < width; x++) {
            unsigned int idx = 3*(y*width + x);
            output_data[idx + 0] = input_data[idx + 0];     //B
            output_data[idx + 1] = input_data[idx + 1];     //G
            output_data[idx + 2] = input_data[idx + 2];     //R
        }
    }
}