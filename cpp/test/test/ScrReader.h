#pragma once

#include <windows.h>
#include <d3d11.h>
#include <dxgi1_2.h>
#include <fstream>
#include "CommonTypes.h"
#include "DuplicationManager.h"

#define USBTERM_SCR_WIDTH  1280
#define USBTERM_SCR_HEIGHT 720

class CScrReader
{
public:
	CScrReader(void);
	~CScrReader(void);
	HRESULT CScrReader::InitializeDx();
	void SaveBitmap(int width, int height, char* pbitmap);
	DUPL_RETURN CopyDirty32to24( _In_ ID3D11Texture2D* SrcSurface );
	DUPL_RETURN CopyDirtyRect32to16( ID3D11Texture2D* SrcSurface, RECT* pDirtyRect );
	DUPL_RETURN ProcessFailure(_In_ LPCWSTR Str, HRESULT hr );
	bool InitFtdi(void);

private:
	DUPLICATIONMANAGER   m_Dupl;
	friend static DWORD WINAPI ThreadScrReader(_In_ void* Param);

	DUPL_RETURN GetFrame(_Out_ FRAME_DATA* Data, _Out_ bool* Timeout);
	DUPL_RETURN CScrReader::ProcessFrame(_In_ FRAME_DATA* Data, INT OffsetX, INT OffsetY, _In_ DXGI_OUTPUT_DESC* DeskDesc );
	ID3D11Texture2D*	 m_MySharedSurf;
	D3D11_TEXTURE2D_DESC m_MySurfDescr;
	ID3D11Device*		 m_Device;
    ID3D11DeviceContext* m_Context;
	ID3D11VertexShader*  m_VertexShader;
	ID3D11PixelShader*   m_PixelShader;
	ID3D11InputLayout*   m_InputLayout;
	ID3D11SamplerState*  m_SamplerLinear;
	PTR_INFO			 m_PtrInfo;
	int					 m_OffsetX;
	int					 m_OffsetY;
	DWORD				 m_ThreadId;
	HANDLE				 m_ThreadHandle;
	int m_file_idx;
	unsigned char*       m_pscreen;
};

