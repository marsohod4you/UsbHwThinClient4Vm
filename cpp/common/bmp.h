#include "ftd2xx.h"

#define PROTO_FLAG_FB			0x00
#define PROTO_FLAG_USB			0x80
#define PROTO_FLAG_USB_LINE		0x40
#define PROTO_FLAG_USB_RESET	0x20
#define PROTO_FLAG_USB_CHANNEL	0x10

int ftdi_init(int idx);
int write_bmp_to_ftdi(int width, int height, unsigned char* ppixels, int stride);
int write_bmp16_to_ftdi(int width, int height, unsigned char* ppixels, RECT* prect );
FT_STATUS FtRawWrite(unsigned char* sbuffer, unsigned long size, unsigned long* psent );
FT_STATUS FtRawRead(unsigned char* rbuffer, unsigned long size, unsigned long* pgot );

