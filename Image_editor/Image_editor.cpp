/*Sablona pro projekty do predmetu IPA, tema graficky editor
*Autor: Tomas Goldmann, igoldmann@fit.vutbr.cz
*
*LOGIN STUDENTA: xpazdi02
*/


#include <opencv2/core/core.hpp>

#include <opencv2/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>
#include <intrin.h>
#include <inttypes.h>
#include <windows.h>
#include "ipa_tool.h"

#define WIN_WIDTH 800.0f
#define PROJECT_NAME "IPA - graficky editor 2017"
#define PROJECT_NAME_WIN_IN "IPA - graficky editor 2017-IN"
#define PROJECT_NAME_WIN_OUT "IPA - graficky editor 2017-OUT"

using namespace cv;
using namespace std;


typedef void(*Ipa_algorithm)(unsigned char *input_data, unsigned char *output_data, unsigned int width, unsigned int height, int argc, char** argv);

int main(int argc, char** argv)
{
	unsigned __int64 cycles_start = 0;
	if (argc < 2)
	{
		cout << " Usage: display_image ImageToLoadAndDisplay" << endl;
		return -1;
	}

	Mat output, window_img,image;
	image = imread(argv[1], CV_LOAD_IMAGE_COLOR);

	if (!image.data)    
	{
		cout << "Could not open or find the image" << std::endl;
		return -1;
	}
	//koeficient pro prijatelne vykresleni
	float q = WIN_WIDTH / static_cast<float>(image.cols);
	
	//vytvoreni vystupniho obrazu	
	image.copyTo(output);

	cv::resize(image, window_img, cv::Size(static_cast<int>(q*image.cols), static_cast<int>(q*image.rows)));

	namedWindow(PROJECT_NAME_WIN_IN, WINDOW_AUTOSIZE);
	imshow(PROJECT_NAME_WIN_IN, window_img);

	HINSTANCE hInstLibrary = LoadLibrary("Student_DLL.dll");

	if (!hInstLibrary)
	{
		std::cout << "DLL Failed To Load!" << std::endl;
		return EXIT_FAILURE;
	}
	else
	{
		//Algoritmus
		InstructionCounter counter;
		Ipa_algorithm f;
		f = (Ipa_algorithm)GetProcAddress(hInstLibrary, "ipa_algorithm");
		if (f)
		{
			counter.start();
			f(image.data, output.data,image.cols, image.rows, argc, argv);
			counter.print();
		}

	}


	namedWindow(PROJECT_NAME_WIN_OUT, WINDOW_AUTOSIZE);
	
	cv::resize(output, output, cv::Size(static_cast<int>(q*image.cols), static_cast<int>(q*image.rows)));
	imshow(PROJECT_NAME_WIN_OUT, output);
	
	waitKey(0); 
	FreeLibrary(hInstLibrary);
	return 0;
}