// usb_mouse_poll.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <windows.h>
#include "../../common/bmp.h"
#include "UsbHidDev.h"

int _tmain(int argc, _TCHAR* argv[])
{
	if( ftdi_init(0) )
	{
		printf("Cannot init FTDI chip\n");
		return -1;
	}

	CUsbHidDev udev;
	udev.HidDevicePoll();
	return 0;
}

