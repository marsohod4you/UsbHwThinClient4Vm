// test.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "scrreader.h"


CScrReader* g_psr;

int _tmain(int argc, _TCHAR* argv[])
{
	g_psr = new CScrReader();
	g_psr->InitFtdi();
	g_psr->InitializeDx();

	while(1)
		Sleep(100);

	return 0;
}

