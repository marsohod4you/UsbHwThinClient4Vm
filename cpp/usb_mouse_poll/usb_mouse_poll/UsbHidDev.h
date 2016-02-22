#pragma once
class CUsbHidDev
{
public:
	CUsbHidDev(void);
	~CUsbHidDev(void);
	int SendUsbCmd( int channel, unsigned char* pCmdBuf, unsigned int cmdlen);
	void PrintBuf(unsigned char *pbuf, int len);
	bool SendCommand(unsigned char* pcmd, int cmd_size);
	int  ReadUsbData(unsigned char* pbuf, int buf_sz);
	bool SendReset();
	bool GetDescriptor0();
	bool GetDescriptor1();
	bool SetAddress();
	bool GetConfiguration9();
	bool GetConfigurationFF();
	bool GetReportDescriptor();
	bool SetConfiguration();
	bool SetKeybLed(int led);
	bool SetMiniKeybLed(int led);
	bool SetIdle();
	bool GetString();
	bool GetProduct();
	bool SetFeature();
	bool ReadKeyb();
	bool ReadMouse();
	bool GetLines(unsigned char* pline);
	bool HidDevicePoll();

	unsigned char m_send_buffer[512];
	bool m_ldown; //mouse buttons
	bool m_mdown;
	bool m_rdown;
	int  m_num_events;
};

