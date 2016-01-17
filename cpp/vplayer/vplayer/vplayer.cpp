// vplayer.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <windows.h>
#include <iostream>
#include <sstream>
#include <fstream>
#include <io.h>
#include <fcntl.h>
#include "../../common/bmp.h"

//use command line to forward frames to this video reader:
//c:\test\ffmpeg -i c:\common\h264\test_video\test_video_640x360.mp4 -c:v bmp -f rawvideo -an - | vplayer.exe
int _tmain(int argc, _TCHAR* argv[])
{
	//std::ofstream ofs;
	//ofs.open ("c:\\common\\output.txt", std::ofstream::out | std::ofstream::app);
	//ofs << "hello" << "\n";

	if( ftdi_init(0)<0 )
	{
		printf("Cannot open FTDI\n");
		return -1;
	}

	_setmode(_fileno(stdin), _O_BINARY);

	//amke memory for video frames
	int buffer_size=1920*1080*4+1024;
	char* pbuffer = (char*)malloc(buffer_size);
	if(pbuffer==NULL)
	{
		printf("cannot alloc memory\n");
		//ofs << "cannot alloc memory" << "\n";
		return -1;
	}

	bool do_cycle = true;
	int idx = 0;

	while ( do_cycle )
	{
		BITMAPFILEHEADER fh;
		size_t got = fread((unsigned char*)&fh, 1, sizeof(fh), stdin);
		if(got!=sizeof(fh))
		{
			printf("read error\n");
			//ofs << "read error" << "\n";
			return -1;
		}
		//ofs << "got: " <<  got << "\n";
		
		//calculate frame size
		int sz = fh.bfSize - sizeof(BITMAPFILEHEADER);

		if(buffer_size<=sz)
		{
			free(pbuffer);
			buffer_size = sz+1024;
			pbuffer = (char*)malloc(buffer_size);
			if(pbuffer==NULL)
			{
				printf("cannot alloc memory\n");
				//ofs << "cannot alloc memory2" << "\n";
				return -1;
			}
		}

		got = fread(pbuffer, 1 , sz, stdin); //read string
		if(got!=sz)
		{
			printf("read error\n");
			//ofs << "read error" << "\n";
			return -1;
		}

		/*
		char fname[1024];
		sprintf_s(fname,"bmp%d.bmp",idx++);
		std::ofstream os(fname, std::ios::out | std::ios::binary);
		os.write ( (char*)&fh, sizeof(fh) );
		os.write ( (char*)pbuffer, sz );
		os.close();
		if(idx>20)
			break;
		*/

		PBITMAPINFO pbmi = (PBITMAPINFO)pbuffer;
		write_bmp_to_ftdi(
			pbmi->bmiHeader.biWidth,
			pbmi->bmiHeader.biHeight,
			(unsigned char*)&pbmi->bmiColors[0],
			pbmi->bmiHeader.biWidth*3
			);

		//ofs << "w: " <<  pbmi->bmiHeader.biWidth << "\n";
		//ofs << "h: " <<  pbmi->bmiHeader.biHeight << "\n";
	}
	free(pbuffer);
	//ofs.close();

	return 0;
}

