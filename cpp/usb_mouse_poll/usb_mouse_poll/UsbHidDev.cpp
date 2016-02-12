#include "stdafx.h"
#include "../../common/bmp.h"
#include "UsbHidDev.h"

// SETUP, GetDescriptor (Device) addr 0/0
static unsigned char usb_setup_GetDescrDevice00[]={ 0x14,0x2D,0x00,0x10, 0x0C,0xC3,0x80,0x06,0x00,0x01,0x00,0x00,0x40,0x00,0xDD,0x94 };

// SETUP, GetDescriptor (Device) addr 1/0
static unsigned char usb_setup_GetDescrDevice10[]={ 0x14,0x2D,0x01,0xE8, 0x0C,0xC3,0x80,0x06,0x00,0x01,0x00,0x00,0x12,0x00,0xE0,0xF4 };

// SETUP, SetAddress(1)
static unsigned char usb_setup_SetAddress1[]    ={ 0x14,0x2D,0x00,0x10, 0x0C,0xC3,0x00,0x05,0x01,0x00,0x00,0x00,0x00,0x00,0xEB,0x25 };

// Empty OUT (no data) addr 0/0
static unsigned char usb_out00[]={ 0x14,0xE1,0x00,0x10, 0x04,0x4B,0x00,0x00 };

// Empty OUT (no data) addr 1/0
static unsigned char usb_out10[]={ 0x14,0xE1,0x01,0xE8, 0x04,0x4B,0x00,0x00 };

// SETUP, GetDescriptor (Configuration 9 bytes) addr 1/0
static unsigned char usb_setup_GetDescrConf9[]={ 0x14,0x2D,0x01,0xE8, 0x0C,0xC3,0x80,0x06,0x00,0x02,0x00,0x00,0x09,0x00,0xAE,0x04 };

// SETUP, GetDescriptor (Configuration FF bytes) addr 1/0
static unsigned char usb_setup_GetDescrConf255[]={ 0x14,0x2D,0x01,0xE8, 0x0C,0xC3,0x80,0x06,0x00,0x02,0x00,0x00,0xFF,0x00,0xE9,0xA4 };

// SETUP, GetDescriptor (String Lang ID) addr 1/0
static unsigned char usb_setup_GetDescrLangId[]={ 0x14,0x2D,0x01,0xE8,0x0C,0xC3,0x80,0x06,0x00,0x03,0x00,0x00,0xFF,0x00,0xD4,0x64 };

// SETUP, GetDescriptor (String iProduct) addr 1/0
static unsigned char usb_setup_GetDescridProd[]={ 0x14,0x2D,0x01,0xE8,0x0C,0xC3,0x80,0x06,0x02,0x03,0x09,0x04,0xFF,0x00,0x97,0xDB };

// SETUP, SetConfiguration addr 1/0
static unsigned char usb_setup_SetConfiguration[]={ 0x14,0x2D,0x01,0xE8,0x0C,0xC3,0x00,0x09,0x01,0x00,0x00,0x00,0x00,0x00,0x27,0x25 };

// SETUP, SetIdle addr 1/0
static unsigned char usb_setup_SetIdle[]={ 0x14,0x2D,0x01,0xE8,0x0C,0xC3,0x21,0x0A,0x00,0x00,0x00,0x00,0x00,0x00,0xD6,0x20 };

// SETUP, GetDescriptor (Report0) addr 1/0
static unsigned char usb_setup_GetDescrReport0[]={ 0x14,0x2D,0x01,0xE8,0x0C,0xC3,0x81,0x06,0x00,0x22,0x00,0x00,0xFF,0x00,0xA9,0xAF };

// SETUP, GetDescriptor (Report1) addr 1/0
static unsigned char usb_setup_GetDescrReport1[]={ 0x14,0x2D,0x01,0xE8,0x0C,0xC3,0x81,0x06,0x00,0x22,0x01,0x00,0xFF,0x00,0xA8,0x53 };

// IN addr 0/0
static unsigned char usb_in00[]={ 0x04,0x69,0x00,0x10 };

// IN addr 1/0
static unsigned char usb_in10[]={ 0x04,0x69,0x01,0xE8 };

// IN addr 1/1
static unsigned char usb_in11[]={ 0x04,0x69,0x81,0x58 };

// IN addr 1/2
static unsigned char usb_in12[]={ 0x04,0x69,0x01,0xC1 };

// SETUP, Set LEDs, kbd
static unsigned char usb_setup_SetKbdLeds[] ={ 0x14,0x2D,0x01,0xE8,0x0C,0xC3,0x21,0x09,0x00,0x02,0x00,0x00,0x01,0x00,0x9D,0x70 };

// SETUP, Set LEDs, mini-kbd
static unsigned char usb_setup_SetKbd2Leds[]={ 0x14,0x2D,0x01,0xE8,0x0C,0xC3,0x21,0x09,0x01,0x02,0x00,0x00,0x02,0x00,0x9C,0x51 };

// LEDs OUT kbd0x---
static unsigned char usb_out_KbdLeds000[]={ 0x14,0xE1,0x01,0xE8,0x05,0x4B,0x00,0x40,0xBF };

// LEDs OUT kbd0x--*
static unsigned char usb_out_KbdLeds001[]={ 0x14,0xE1,0x01,0xE8,0x05,0x4B,0x01,0x81,0x7F };

// LEDs OUT kbd0x-*-
static unsigned char usb_out_KbdLeds010[]={ 0x14,0xE1,0x01,0xE8,0x05,0x4B,0x02,0xC1,0x7E };

// LEDs OUT kbd0x-**
static unsigned char usb_out_KbdLeds011[]={ 0x14,0xE1,0x01,0xE8,0x05,0x4B,0x03,0x00,0xBE };

// LEDs OUT kbd0x*--
static unsigned char usb_out_KbdLeds100[]={ 0x14,0xE1,0x01,0xE8,0x05,0x4B,0x04,0x41,0x7C };

// LEDs OUT kbd0x*-*
static unsigned char usb_out_KbdLeds101[]={ 0x14,0xE1,0x01,0xE8,0x05,0x4B,0x05,0x80,0xBC };

// LEDs OUT kbd0x**-
static unsigned char usb_out_KbdLeds110[]={ 0x14,0xE1,0x01,0xE8,0x05,0x4B,0x06,0xC0,0xBD };

// LEDs OUT kbd0x***
static unsigned char usb_out_KbdLeds111[]={ 0x14,0xE1,0x01,0xE8,0x05,0x4B,0x07,0x01,0x7D };

// LEDs OUT minikbd0x---
static unsigned char usb_out_mKbdLeds000[]={ 0x14,0xE1,0x01,0xE8,0x06,0x4B,0x01,0x00,0xFF,0xDF };

// LEDs OUT minikbd0x--*
static unsigned char usb_out_mKbdLeds001[]={ 0x14,0xE1,0x01,0xE8,0x06,0x4B,0x01,0x01,0x3E,0x1F };

// LEDs OUT minikbd0x-*-
static unsigned char usb_out_mKbdLeds010[]={ 0x14,0xE1,0x01,0xE8,0x06,0x4B,0x01,0x02,0x7E,0x1E };

// LEDs OUT minikbd0x-**
static unsigned char usb_out_mKbdLeds011[]={ 0x14,0xE1,0x01,0xE8,0x06,0x4B,0x01,0x03,0xBF,0xDE };

// LEDs OUT minikbd0x*--
static unsigned char usb_out_mKbdLeds100[]={ 0x14,0xE1,0x01,0xE8,0x06,0x4B,0x01,0x04,0xFE,0x1C };

// LEDs OUT minikbd0x*-*
static unsigned char usb_out_mKbdLeds101[]={ 0x14,0xE1,0x01,0xE8,0x06,0x4B,0x01,0x05,0x3F,0xDC };

// LEDs OUT minikbd0x**-
static unsigned char usb_out_mKbdLeds110[]={ 0x14,0xE1,0x01,0xE8,0x06,0x4B,0x01,0x06,0x7F,0xDD };

// LEDs OUT minikbd0x***
static unsigned char usb_out_mKbdLeds111[]={ 0x14,0xE1,0x01,0xE8,0x06,0x4B,0x01,0x07,0xBE,0x1D };


CUsbHidDev::CUsbHidDev(void)
{
}


CUsbHidDev::~CUsbHidDev(void)
{
}

int CUsbHidDev::SendUsbCmd( int channel, unsigned char* pCmdBuf, unsigned int cmdlen)
{
	if(cmdlen>255 )
		return -1; //error, too big command

	unsigned char* pdest = m_send_buffer;
	unsigned long size = cmdlen+4; 
	//make header SIGNATURE & Length
	pdest[0]=(unsigned char)cmdlen;
	pdest[1]=0x80; //high bit mean usb command, not a framebuffer write
	pdest[2]=0x55;
	pdest[3]=0xaa;

	unsigned long sent=0;
	FT_STATUS st = FtRawWrite(m_send_buffer, size, &sent);
	if( st==FT_OK)
		return 0;
	return -1;
}

//--------------------------------------
void CUsbHidDev::PrintBuf(unsigned char *pbuf, int len)
{
	int i;

	if( (len==0) || (pbuf==0) )
		return;

	for(i=0; i<len; i++)
	{
		if( ((i&0xF)==0)&&(i) ) printf("\n");
		printf(" %02X",pbuf[i]);
	}

	printf("\n");
}

bool CUsbHidDev::SendReset()
{
	return true;
}

bool CUsbHidDev::GetDescriptor0()
{
	return true;
}

bool CUsbHidDev::GetDescriptor1()
{
	return true;
}

bool CUsbHidDev::SetAddress()
{
	return true;
}

bool CUsbHidDev::GetConfiguration9()
{
	return true;
}

bool CUsbHidDev::GetConfigurationFF()
{
	return true;
}

bool CUsbHidDev::GetReportDescriptor()
{
	return true;
}

bool CUsbHidDev::SetConfiguration()
{
	return true;
}

bool CUsbHidDev::SetKeybLed(int led)
{
	return true;
}

bool CUsbHidDev::SetMiniKeybLed(int led)
{
	return true;
}

bool CUsbHidDev::SetIdle()
{
	return true;
}


bool CUsbHidDev::GetString()
{
	return true;
}

bool CUsbHidDev::GetProduct()
{
	return true;
}

bool CUsbHidDev::SetFeature()
{
	return true;
}

bool CUsbHidDev::GetLines( unsigned char* pline )
{
	//make header SIGNATURE & Length
	m_send_buffer[0]=1;
	m_send_buffer[1]=0;
	m_send_buffer[2]=0x55;
	m_send_buffer[3]=0xaa;
	m_send_buffer[4]=0;
	m_send_buffer[5]=0;
	m_send_buffer[6]=0;
	m_send_buffer[7]=0x80;
	m_send_buffer[8]=0x35; //usb byte..
	m_send_buffer[9]=0;

	unsigned long sent=0;
	FT_STATUS st = FtRawWrite(m_send_buffer, 10, &sent);
	if( st!=FT_OK)
		return false;

	/*
	unsigned long got=0;
	st = FtRawRead(pline, 1, &got);
	if( st!=FT_OK)
		return false;
	if( got!=1)
		return false;
	*/
	return true;
}

bool CUsbHidDev::ReadKeyb()
{
	return true;
}

bool CUsbHidDev::ReadMouse()
{
	unsigned char mouse_data[128];
	char* pMouseData = 2 + (char*)mouse_data;

	int got=0;
	for(int i=0; i<32; i++)
		mouse_data[i]=0x33;

	//got = SendUsbCmd(0x10,mouse_data);
	if(got==2 && mouse_data[1]==0x5A)
		return true; //it is USB NAK

	if(got==1 && mouse_data[0]==0xFF)
	{
		printf("FF err\n");
		return false; //it is ERR
	}

	if(got==0)
	{
		return false; //it is ERR
	}

	int dx,dy;
	dx = pMouseData[1];
	dy = pMouseData[2];
	//printf("%02X %02X %08X\t%d\t%d\n",mouse_data[0],mouse_data[1],*(unsigned int*)pMouseData,dx,dy);

	unsigned int flag = MOUSEEVENTF_MOVE; 

	if(pMouseData[0]&1)
	{
		if(!m_ldown)
		{
			flag = flag | MOUSEEVENTF_LEFTDOWN;
			m_ldown = true;
		}
	}
	else
	{
		if(m_ldown)
		{
			flag = flag | MOUSEEVENTF_LEFTUP;
			m_ldown = false;
		}
	}

	if(pMouseData[0]&2)
	{
		if(!m_rdown)
		{
			flag = flag | MOUSEEVENTF_RIGHTDOWN;
			m_rdown = true;
		}
	}
	else
	{
		if(m_rdown)
		{
			flag = flag | MOUSEEVENTF_RIGHTUP;
			m_rdown = false;
		}
	}

	mouse_event(flag,dx,dy,0,0);
	return true;
}

bool CUsbHidDev::HidDevicePoll()
{
	while(1)
	{
		//wait for USB attach
		UCHAR CurrentUsbLines=0;
		GetLines( &CurrentUsbLines );
		printf("CurrentUsbLines %02X\n",CurrentUsbLines);
		if( (CurrentUsbLines & 0x03) != 0x01)
		{
			//nothin attached
			Sleep(1000);
			continue;
		}

		//something attached

		SendReset();
		GetDescriptor0();
		SetAddress();
		GetDescriptor1();
		GetConfiguration9();
		GetConfigurationFF();
		//GetString();
		//GetProduct();
		SetConfiguration();
		//SetIdle();
		GetReportDescriptor();

		while(1)
		{
			ReadMouse();
		}
	}
	return 0;
}

