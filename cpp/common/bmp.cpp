// leds.cpp: определяет точку входа для консольного приложения.
//

#include "stdafx.h"
#include <string.h>
#include <windows.h>
#include "atlimage.h"
#include "bmp.h"

FT_HANDLE ftHandle; // Handle of the FTDI device
FT_STATUS ftStatus; // Result of each D2XX call
DWORD dwNumDevs; // The number of devices
DWORD dwNumBytesToRead = 0; // Number of bytes available to read in the driver's input buffer
DWORD dwNumBytesRead;
unsigned char byInputBuffer[1024]; // Buffer to hold data read from the FT2232H
DWORD dwNumBytesSent;
DWORD dwNumBytesToSend;

#define BUF_SIZE (1024*16)
unsigned char byOutputBuffer[BUF_SIZE*2]; // Buffer to hold MPSSE commands and data to be sent to the FT2232H
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


ftHandle=NULL;

//dwNumDevs = idx+1;

//go thru' list of devices
for(unsigned int i=idx; i<dwNumDevs; i++)
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

printf("FT HANDLE %p\n",ftHandle);

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

void get_hicolor_line32( unsigned short* pdst16, unsigned char* psrc32, int numpix)
{
	for(int i=0; i<numpix; i++)
	{
		unsigned short r,g,b;
		b = psrc32[0];
		g = psrc32[1];
		r = psrc32[2];
		psrc32+=4;

		unsigned short h = ((r & 0xf8) << 8) | ((g & 0xfc) << 3) | ((b & 0xf8) >>3);
		*pdst16 = h;
		pdst16++;
	}
}

void get_hicolor_line_( unsigned short* pdst16, unsigned char* psrc24, int numpix)
{
	for(int i=0; i<numpix; i++)
	{
		unsigned short h = i&7;
		*pdst16 = h;
		pdst16++;
	}
}

int write_bmp_to_ftdi(int width, int height, unsigned char* ppixels, int stride)
{
	int top  = 0;
	int left = 0;
	int lenp = 256;

	unsigned char* pdest = byOutputBuffer;
	int total_sz = 0;
	
	for(int y=0; y<720; y++)
	{
		for(int x=0; x<(1280/lenp); x++)
		{
			int yy = 719-y;

			//make header SIGNATURE & Length
			pdest[0]=lenp&0xFF;
			pdest[1]=lenp>>8;
			pdest[2]=0x55;
			pdest[3]=0xaa;

			//target framebuffer address
			unsigned int* paddr = (unsigned int*)&pdest[4];
			paddr[0] = (yy+top)*1024*4+left+x*lenp;

			get_hicolor_line( (unsigned short*)&pdest[8],ppixels+stride*y+lenp*3*x,lenp);

			total_sz += lenp*2+8;
			pdest += lenp*2+8;

			if( total_sz > BUF_SIZE )
			{
				//time to flush accumulated
				FT_Write(ftHandle, byOutputBuffer, total_sz, &dwNumBytesSent);
				total_sz = 0;
				pdest = byOutputBuffer;
			}
		}
	}

	//flush acumulated
	if( total_sz )
	{
		//time to flush accumulated
		FT_Write(ftHandle, byOutputBuffer, total_sz, &dwNumBytesSent);
		total_sz = 0;
		pdest = byOutputBuffer;
	}
	return 0;
}

int once = 1;
int write_bmp16_to_ftdi(int width, int height, unsigned char* ppixels, RECT* prect )
{
	int stride = width*2;

	//align source rectangle left/right coords
	prect->left  &= 0xFFF8; 
	prect->right = (prect->right+7) & 0xFFF8;
	int rwidth = prect->right-prect->left;

	int lenp = 256;
	if(lenp>rwidth)
		lenp=rwidth;

	unsigned char* pdest = byOutputBuffer;
	int total_sz = 0;
	
	for(int y=prect->top; y<prect->bottom; y++)
	{
		for(int x=prect->left; x<prect->right; x=x+lenp )
		{
			//make header SIGNATURE & Length
			pdest[0]=lenp&0xFF;
			pdest[1]=lenp>>8;
			pdest[2]=0x55;
			pdest[3]=0xaa;

			//target framebuffer address
			unsigned int* paddr = (unsigned int*)&pdest[4];
			paddr[0] = y*1024*4+x;

			memcpy( &pdest[8], ppixels+stride*y+x*2, lenp*2);

			total_sz += lenp*2+8;
			pdest += lenp*2+8;

			if( total_sz > BUF_SIZE )
			{
				//time to flush accumulated
				FT_STATUS st = FT_Write(ftHandle, byOutputBuffer, total_sz, &dwNumBytesSent);
				if(st && once)
				{
					once=0;
					printf("fth %p %d \n",ftHandle,st);
				}
				total_sz = 0;
				pdest = byOutputBuffer;
			}
		}
	}

	//flush acumulated
	if( total_sz )
	{
		//time to flush accumulated
		FT_Write(ftHandle, byOutputBuffer, total_sz, &dwNumBytesSent);
		total_sz = 0;
		pdest = byOutputBuffer;
	}

	return 0;
}

FT_STATUS FtRawWrite(unsigned char* sbuffer, unsigned long size, unsigned long* psent )
{
	return FT_Write( ftHandle, sbuffer, size, psent );
}

FT_STATUS FtRawRead(unsigned char* rbuffer, unsigned long size, unsigned long* pgot )
{
	return FT_Read( ftHandle, rbuffer, size, pgot );
}