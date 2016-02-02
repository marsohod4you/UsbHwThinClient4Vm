
int ftdi_init(int idx);
int write_bmp_to_ftdi(int width, int height, unsigned char* ppixels, int stride);
int write_bmp16_to_ftdi(int width, int height, unsigned char* ppixels, RECT* prect );
