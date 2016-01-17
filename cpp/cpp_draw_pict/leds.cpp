// leds.cpp: определяет точку входа для консольного приложения.
//

#include "stdafx.h"
#include <string.h>
#include <windows.h>
#include "atlimage.h"
#include "../common/bmp.h"

int _tmain(int argc, _TCHAR* argv[])
{
	if(argc<3)
	{
		printf("Need param FTDI chip num and bitmap/jpeg file\n");
		return -1;
	}

	_TCHAR* pstr = argv[1];
	int ar = pstr[0]-0x30;
	int idx=(ar&1)*2;

	if( ftdi_init(idx) )
	{
		printf("Cannot init FTDI chip\n");
		return -1;
	}

	CImage img;
	HRESULT r = img.Load(argv[2]);
	if(r!=S_OK)
	{
		wprintf(_T("Error, cannot load file %s\n"),argv[1]);
		return -1;
	}

	//get image file parameters
	int width  = img.GetWidth();
	int height = img.GetHeight();
	unsigned char* ppixels = (unsigned char*)img.GetBits();
	int stride = img.GetPitch();
	wprintf(_T("File %s, width %d height %d stride %d\n"),argv[1],width,height,stride);

	//bitmap is vertically swapped and ppixels points to last line
	//go to first line
	if(stride<0)
	{
		stride = -stride;
		ppixels = ppixels - stride*(height-1);
	}

	DWORD t1 = GetTickCount();
	
	write_bmp_to_ftdi(width,height,ppixels,stride);
	
	DWORD t2 = GetTickCount();
	printf("time lapse %d\n",t2-t1);

	return 0;
}
