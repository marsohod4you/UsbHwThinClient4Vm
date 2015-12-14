// leds.cpp: определяет точку входа для консольного приложения.
//

#include "stdafx.h"
#include <string.h>
#include <windows.h>
#include "atlimage.h"
#include "ftd2xx.h"

FT_HANDLE ftHandle; // Handle of the FTDI device
FT_STATUS ftStatus; // Result of each D2XX call
DWORD dwNumDevs; // The number of devices
DWORD dwNumBytesToRead = 0; // Number of bytes available to read in the driver's input buffer
DWORD dwNumBytesRead;
unsigned char byInputBuffer[1024]; // Buffer to hold data read from the FT2232H
DWORD dwNumBytesSent;
DWORD dwNumBytesToSend;
unsigned char byOutputBuffer[1024]; // Buffer to hold MPSSE commands and data to be sent to the FT2232H
int ft232H = 0; // High speed device (FTx232H) found. Default - full speed, i.e. FT2232D
DWORD dwClockDivisor = 0;
DWORD dwCount;

int ftdi_init(int idx)
{
FT_DEVICE ftDevice; 
DWORD deviceID; 
char SerialNumber[16+1]; 
char Description[64+1]; 

// Does an FTDI device exist?
printf("Checking for FTDI devices...\n");

/*
ftStatus = FT_CreateDeviceInfoList(&dwNumDevs);

// Get the number of FTDI devices
if (ftStatus != FT_OK) // Did the command execute OK?
{
	printf("Error in getting the number of devices\n");
	return 1; // Exit with error
}

if (dwNumDevs < 1) // Exit if we don't see any
{
	printf("There are no FTDI devices installed\n");
	return 1; // Exist with error
}

printf("%d FTDI devices found - the count includes individual ports on a single chip\n", dwNumDevs);
*/

ftHandle=NULL;

dwNumDevs = idx+1;

//go thru' list of devices
for(int i=idx; i<dwNumDevs; i++)
{
	printf("Open port %d\n",i);
	ftStatus = FT_Open(i, &ftHandle);
	if (ftStatus != FT_OK)
	{
		printf("Open Failed with error %d\n", ftStatus);
		printf("If runing on Linux then try <rmmod ftdi_sio> first\n");
		continue;
	}

	FT_PROGRAM_DATA ftData; 
	char ManufacturerBuf[32]; 
	char ManufacturerIdBuf[16]; 
	char DescriptionBuf[64]; 
	char SerialNumberBuf[16]; 

	ftData.Signature1 = 0x00000000; 
	ftData.Signature2 = 0xffffffff; 
	ftData.Version = 0x00000003;      //3 = FT2232H extensions
	ftData.Manufacturer = ManufacturerBuf; 
	ftData.ManufacturerId = ManufacturerIdBuf; 
	ftData.Description = DescriptionBuf; 
	ftData.SerialNumber = SerialNumberBuf; 
	ftStatus = FT_EE_Read(ftHandle,&ftData);
	if (ftStatus == FT_OK)
	{ 
		printf("\tDevice: %s\n\tSerial: %s\n", ftData.Description, ftData.SerialNumber);
		printf("\tDevice Type: %02X\n", ftData.IFAIsFifo7 );
		break;
	}
	else
	{
		printf("\tCannot read ext flash\n");
		FT_Close(ftHandle);
	}
}

if(ftHandle==NULL)
{
	printf("NO FTDI chip with FIFO function\n");
	return -1;
}

//ENABLE SYNC FIFO MODE
ftStatus |= FT_SetBitMode(ftHandle, 0xFF, 0x00);
ftStatus |= FT_SetBitMode(ftHandle, 0xFF, 0x40);

if (ftStatus != FT_OK)
{
	printf("Error in initializing1 %d\n", ftStatus);
	FT_Close(ftHandle);
	return 1; // Exit with error
}

UCHAR LatencyTimer = 2; //our default setting is 2
ftStatus |= FT_SetLatencyTimer(ftHandle, LatencyTimer); 
ftStatus |= FT_SetUSBParameters(ftHandle,0x10000,0x10000);
ftStatus |= FT_SetFlowControl(ftHandle,FT_FLOW_RTS_CTS,0x10,0x13);

if (ftStatus != FT_OK)
{
	printf("Error in initializing2 %d\n", ftStatus);
	FT_Close(ftHandle);
	return 1; // Exit with error
}

//return with success
return 0;
}

#define NUMB 64

void get_hicolor_line( unsigned short* pdst16, unsigned char* psrc24, int numpix)
{
	for(int i=0; i<numpix; i++)
	{
		unsigned short r,g,b;
		b = psrc24[0];
		g = psrc24[1];
		r = psrc24[2];
		psrc24+=3;

		unsigned short h = ((r & 0xf8) << 8) | ((g & 0xfc) << 3) | ((b & 0xf8) >>3);
		*pdst16 = h;
		pdst16++;
	}
}

int _tmain(int argc, _TCHAR* argv[])
{
	if(argc<3)
	{
		printf("Need param port num and bitmap/jpeg file\n");
		return -1;
	}

	int idx=0;
	_TCHAR* pstr = argv[2];
	if(pstr[0]=='1')
		idx=1;

	if( ftdi_init(idx) )
	{
		printf("Cannot init FTDI chip\n");
		return -1;
	}

	CImage img;
	HRESULT r = img.Load(argv[2]);
	if(r!=S_OK)
	{
		wprintf(_T("error, cannot load file %s\n"),argv[1]);
		return -1;
	}

	//get image file parameters
	int width  = img.GetWidth();
	int height = img.GetHeight();
	unsigned char* ppixels = (unsigned char*)img.GetBits();
	int stride = img.GetPitch();
	wprintf(_T("file %s, width %d height %d stride %d\n"),argv[1],width,height,stride);

	//bitmap is vertically swapped and ppixels points to last line
	//go to first line
	if(stride<0)
	{
		stride = -stride;
		ppixels = ppixels - stride*(height-1);
	}

	int top = 32;
	int left = 64;
	int lenp = 16;

	byOutputBuffer[0]=lenp/2;
	byOutputBuffer[1]=0x00;
	byOutputBuffer[2]=0x00;
	byOutputBuffer[3]=0x00;
	byOutputBuffer[4]=0x00;
	byOutputBuffer[5]=0x40;
	byOutputBuffer[6]=0x00;
	byOutputBuffer[7]=0x00;
	//for( int i=0; i<NUMB; i++)
	//	byOutputBuffer[8+i] = (i&1) ? 0:0xFF;


	for(int x=0; x<32; x++)
	{
		for(int y=0; y<400; y++)
		{
			get_hicolor_line( (unsigned short*)&byOutputBuffer[8],ppixels+stride*y+lenp*3*x,lenp);

			unsigned int* paddr = (unsigned int*)&byOutputBuffer[4];
			paddr[0] = (y+top)*1024*4+left+x*lenp/2;
			FT_Write(ftHandle, byOutputBuffer, lenp*2+8, &dwNumBytesSent);
		}
	}

	return 0;
}
