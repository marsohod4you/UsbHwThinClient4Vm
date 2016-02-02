#include "stdafx.h"
#include "ScrReader.h"
#include "../../common/bmp.h"

//
// Entry point for new duplication threads
//
static DWORD WINAPI ThreadScrReader(_In_ void* Param)
{
	printf("thread runs\n");
    // Data passed in from thread creation
    CScrReader* pScrReader = reinterpret_cast<CScrReader*>(Param);

    HDESK CurrentDesktop = nullptr;
    CurrentDesktop = OpenInputDesktop(0, FALSE, GENERIC_ALL);
    if (!CurrentDesktop)
    {
        // cannot open current input desktop?
        goto Exit;
    }

	// Attach desktop to this thread
    bool DesktopAttached = SetThreadDesktop(CurrentDesktop) != 0;
    CloseDesktop(CurrentDesktop);
    CurrentDesktop = nullptr;
    if (!DesktopAttached)
    {
        // We do not have access to the desktop so request a retry
        goto Exit;
    }

	///////////////////////
	D3D11_TEXTURE2D_DESC DeskTexD;
	RtlZeroMemory(&DeskTexD, sizeof(D3D11_TEXTURE2D_DESC));
    DeskTexD.Width = 1920;
    DeskTexD.Height = 1080;
    DeskTexD.MipLevels = 1;
    DeskTexD.ArraySize = 1;
    DeskTexD.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    DeskTexD.SampleDesc.Count = 1;
    DeskTexD.Usage = D3D11_USAGE_STAGING;
    DeskTexD.BindFlags = 0;
    DeskTexD.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    DeskTexD.MiscFlags = 0;

    HRESULT hr = pScrReader->m_Device->CreateTexture2D(&DeskTexD, nullptr, &pScrReader->m_MySharedSurf);
    if (FAILED(hr))
    {
		return pScrReader->ProcessFailure(L"Failed to create MY shared texture", hr);
    }

    // Make duplication manager
	UINT Output=0;
    DUPL_RETURN Ret = pScrReader->m_Dupl.InitDupl(pScrReader->m_Device, pScrReader, Output);
    if (Ret != DUPL_RETURN_SUCCESS)
    {
        goto Exit;
    }

    // Get output description
    DXGI_OUTPUT_DESC DesktopDesc;
    RtlZeroMemory(&DesktopDesc, sizeof(DXGI_OUTPUT_DESC));
    pScrReader->m_Dupl.GetOutputDesc(&DesktopDesc);

    // Main duplication loop
    bool WaitToProcessCurrentFrame = false;
    FRAME_DATA CurrentData;

    while ( /*(WaitForSingleObjectEx(TData->TerminateThreadsEvent, 0, FALSE) == WAIT_TIMEOUT)*/ 1)
    {
        if (!WaitToProcessCurrentFrame)
        {
            // Get new frame from desktop duplication
            bool TimeOut;
            Ret = pScrReader->m_Dupl.GetFrame(&CurrentData, &TimeOut);
            if (Ret != DUPL_RETURN_SUCCESS)
            {
                // An error occurred getting the next frame drop out of loop which
                // will check if it was expected or not
                break;
            }

            // Check for timeout
            if (TimeOut)
            {
                // No new frame at the moment
				//pScrReader->SaveBitmap(pScrReader->m_MySurfDescr.Width,pScrReader->m_MySurfDescr.Height,(char*)pScrReader->m_pscreen);
				//write_bmp_to_ftdi(pScrReader->m_MySurfDescr.Width,pScrReader->m_MySurfDescr.Height,pScrReader->m_pscreen,pScrReader->m_MySurfDescr.Width*3);
                continue;
            }
        }

        // We can now process the current frame
        WaitToProcessCurrentFrame = false;

        // Get mouse info
        Ret = pScrReader->m_Dupl.GetMouse(&pScrReader->m_PtrInfo, &(CurrentData.FrameInfo), pScrReader->m_OffsetX, pScrReader->m_OffsetY);
        if (Ret != DUPL_RETURN_SUCCESS)
        {
            pScrReader->m_Dupl.DoneWithFrame();
            break;
        }

		// Process new frame
		Ret = pScrReader->ProcessFrame(&CurrentData, pScrReader->m_OffsetX, pScrReader->m_OffsetY, &DesktopDesc);
        /*
		if (Ret != DUPL_RETURN_SUCCESS)
        {
            pScrReader->m_Dupl.DoneWithFrame();
            KeyMutex->ReleaseSync(1);
            break;
        }
		*/

        // Release frame back to desktop duplication
        Ret = pScrReader->m_Dupl.DoneWithFrame();
        if (Ret != DUPL_RETURN_SUCCESS)
        {
            break;
        }
    }

Exit:
	printf("thread stops\n");
    return 0;
}


CScrReader::CScrReader(void)
{
	m_file_idx = 0;
	m_MySharedSurf = nullptr;
	m_pscreen = new unsigned char[1920*1080*4+1024];
	memset(&m_PtrInfo,0,sizeof(m_PtrInfo));
}

CScrReader::~CScrReader(void)
{
}

bool CScrReader::InitFtdi(void)
{
	if( ftdi_init(0)<0 )
	{
		//printf("Cannot open FTDI\n");
		return false;
	}
	return true;
}

void CScrReader::SaveBitmap(int width, int height, char* pbitmap)
{
	// Bitmap structures to be written to file
    BITMAPFILEHEADER bfh;
    BITMAPINFOHEADER bih;
 
    // Fill BITMAPFILEHEADER structure
    memcpy((char *)&bfh.bfType, "BM", 2);
    bfh.bfSize = sizeof(bfh) + sizeof(bih) + 3*width*height;
    bfh.bfReserved1 = 0;
    bfh.bfReserved2 = 0;
    bfh.bfOffBits = sizeof(bfh) + sizeof(bih);
 
    // Fill BITMAPINFOHEADER structure
    bih.biSize = sizeof(bih);
    bih.biWidth = width;
    bih.biHeight = height;
    bih.biPlanes = 1;
    bih.biBitCount = 24;
    bih.biCompression = BI_RGB; // uncompressed 24-bit RGB
    bih.biSizeImage = 0; // can be zero for BI_RGB bitmaps
    bih.biXPelsPerMeter = 3780; // 96dpi equivalent
    bih.biYPelsPerMeter = 3780;
    bih.biClrUsed = 0;
    bih.biClrImportant = 0;
 
    // Open bitmap file (binary mode)
    FILE *f;
	char fname[256];
	sprintf_s( fname,sizeof(fname),"c:\\common\\image%d.bmp",m_file_idx);
    int err = fopen_s( &f, fname, "wb");
	m_file_idx = (m_file_idx+1) & 0x3f;

 
    // Write bitmap file header
    fwrite(&bfh, 1, sizeof(bfh), f);
    fwrite(&bih, 1, sizeof(bih), f);
	fwrite(pbitmap,1,3*width*height,f);
 
    // Close bitmap file
    fclose(f);
}

DUPL_RETURN CScrReader::CopyDirty32to24( _In_ ID3D11Texture2D* SrcSurface )
{
	m_Context->CopyResource(m_MySharedSurf,SrcSurface);
	D3D11_MAPPED_SUBRESOURCE mapped_data;
    unsigned int subresource = D3D11CalcSubresource( 0, 0, 0 );
	HRESULT hr = m_Context->Map( m_MySharedSurf, subresource, D3D11_MAP_READ, 0, &mapped_data );
	m_MySharedSurf->GetDesc(&m_MySurfDescr);
	const int pitch = m_MySurfDescr.Width << 2;
	const unsigned char* source = static_cast< const unsigned char* >( mapped_data.pData );
	unsigned char* dest = m_pscreen;
    for( unsigned int i = 0; i < m_MySurfDescr.Height; ++i )
    {
        //memcpy( dest, source, descr.Width * 4 );
		for( unsigned int x=0; x<m_MySurfDescr.Width; x++)
		{
			dest[x*3+0]=source[x*4+0];
			dest[x*3+1]=source[x*4+1];
			dest[x*3+2]=source[x*4+2];
		}
        source += pitch;
        dest += m_MySurfDescr.Width*3;
    }
	m_Context->Unmap( m_MySharedSurf,subresource);
	return DUPL_RETURN_SUCCESS;
}

//copy rectangle area from source surface to shared surface,
//then map shared surface for CPU access and copy pixels converting to 16 bits-per-pixel
DUPL_RETURN CScrReader::CopyDirtyRect32to16(  ID3D11Texture2D* SrcSurface, RECT* pDirtyRect )
{
	//check input rectangle is valid
	if(pDirtyRect->left<0)
		pDirtyRect->left=0;
	if(pDirtyRect->top<0)
		pDirtyRect->top=0;
	if(pDirtyRect->right>USBTERM_SCR_WIDTH)
		pDirtyRect->right=USBTERM_SCR_WIDTH;
	if(pDirtyRect->bottom>USBTERM_SCR_HEIGHT)
		pDirtyRect->bottom=USBTERM_SCR_HEIGHT;

	D3D11_TEXTURE2D_DESC d;
	SrcSurface->GetDesc(&d);
	
	//copy region from src surface to shared surf
	this->m_Context->CopyResource(m_MySharedSurf,SrcSurface);

	//map shared surface
	D3D11_MAPPED_SUBRESOURCE mapped_data;
    unsigned int subresource = D3D11CalcSubresource( 0, 0, 0 );
	HRESULT hr = m_Context->Map( m_MySharedSurf, subresource, D3D11_MAP_READ, 0, &mapped_data );
	m_MySharedSurf->GetDesc(&m_MySurfDescr);
	//printf("fmt1 %d fmt2 %d\n",d.Format,m_MySurfDescr.Format);
	//printf( "%d %d %d %d\n",d.SampleDesc.Count,d.SampleDesc.Quality,m_MySurfDescr.SampleDesc.Count,m_MySurfDescr.SampleDesc.Quality);
	const int pitch = m_MySurfDescr.Width << 2;
	
	//copy rectangle to local memory and convert to high-color
	unsigned char* source_screen = static_cast< unsigned char* >( mapped_data.pData );
	for( int y=pDirtyRect->top; y<pDirtyRect->bottom; y++ )
    {
		unsigned char*  psrc = source_screen+y*pitch;
		unsigned short* pdst = (unsigned short*)(m_pscreen+y*USBTERM_SCR_WIDTH*2+pDirtyRect->left*2);
		for( int x=pDirtyRect->left; x<pDirtyRect->right; x++)
		{
			unsigned short b = psrc[x*4+0];
			unsigned short g = psrc[x*4+1];
			unsigned short r = psrc[x*4+2];
			unsigned short h = ((r & 0xf8) << 8) | ((g & 0xfc) << 3) | ((b & 0xf8) >>3);
			*pdst++=h;
		}
    }
	//unmap shared surface
	m_Context->Unmap((ID3D11Resource*)m_MySharedSurf,subresource);

	write_bmp16_to_ftdi(USBTERM_SCR_WIDTH,USBTERM_SCR_HEIGHT,m_pscreen,pDirtyRect);

	return DUPL_RETURN_SUCCESS;
}

//
// Get DX_RESOURCES
//
HRESULT CScrReader::InitializeDx()
{
    HRESULT hr = S_OK;

    // Driver types supported
    D3D_DRIVER_TYPE DriverTypes[] =
    {
        D3D_DRIVER_TYPE_HARDWARE,
        D3D_DRIVER_TYPE_WARP,
        D3D_DRIVER_TYPE_REFERENCE,
    };
    UINT NumDriverTypes = ARRAYSIZE(DriverTypes);

    // Feature levels supported
    D3D_FEATURE_LEVEL FeatureLevels[] =
    {
        D3D_FEATURE_LEVEL_11_0,
        D3D_FEATURE_LEVEL_10_1,
        D3D_FEATURE_LEVEL_10_0,
        D3D_FEATURE_LEVEL_9_1
    };
    UINT NumFeatureLevels = ARRAYSIZE(FeatureLevels);

    D3D_FEATURE_LEVEL FeatureLevel;

    // Create device
    for (UINT DriverTypeIndex = 0; DriverTypeIndex < NumDriverTypes; ++DriverTypeIndex)
    {
        hr = D3D11CreateDevice(nullptr, DriverTypes[DriverTypeIndex], nullptr, 0, FeatureLevels, NumFeatureLevels,
                                D3D11_SDK_VERSION, &m_Device, &FeatureLevel, &m_Context);
        if (SUCCEEDED(hr))
        {
            // Device creation success, no need to loop anymore
			printf("DX driver type index %d feature level %d\n",DriverTypeIndex,FeatureLevel);
            break;
        }
    }
    if (FAILED(hr))
    {
		// Device creation failed
		return ProcessFailure( L"DX Device creation failed", hr );
		return hr;
    }

    // VERTEX shader
	/*
    UINT Size = ARRAYSIZE(g_VS);
    hr = m_Device->CreateVertexShader(g_VS, Size, nullptr, &m_VertexShader);
    if (FAILED(hr))
    {
        return ProcessFailure( L"Failed to create vertex shader in InitializeDx",  hr );
    }
	*/

    // Input layout
    D3D11_INPUT_ELEMENT_DESC Layout[] =
    {
        {"POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0},
        {"TEXCOORD", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 12, D3D11_INPUT_PER_VERTEX_DATA, 0}
    };

	/*
    UINT NumElements = ARRAYSIZE(Layout);
    hr = m_Device->CreateInputLayout(Layout, NumElements, g_VS, Size, &m_InputLayout);
    if (FAILED(hr))
    {
        return ProcessFailure( L"Failed to create input layout in InitializeDx", hr );
	}
    
	m_Context->IASetInputLayout(m_InputLayout);
	*/

	/*
    // Pixel shader
    Size = ARRAYSIZE(g_PS);
    hr = m_Device->CreatePixelShader(g_PS, Size, nullptr, &m_PixelShader);
    if (FAILED(hr))
    {
        return ProcessFailure( L"Failed to create pixel shader in InitializeDx", hr );
    }
	*/

    // Set up sampler
    D3D11_SAMPLER_DESC SampDesc;
    RtlZeroMemory(&SampDesc, sizeof(SampDesc));
    SampDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
    SampDesc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
    SampDesc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
    SampDesc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
    SampDesc.ComparisonFunc = D3D11_COMPARISON_NEVER;
    SampDesc.MinLOD = 0;
    SampDesc.MaxLOD = D3D11_FLOAT32_MAX;
    hr = m_Device->CreateSamplerState(&SampDesc, &m_SamplerLinear);
    if (FAILED(hr))
    {
        return ProcessFailure( L"Failed to create sampler state in InitializeDx", hr );
    }

	DWORD ThreadId;
    m_ThreadHandle = CreateThread(nullptr, 0, ThreadScrReader, this, 0, &ThreadId);
    if (m_ThreadHandle == nullptr)
    {
        return ProcessFailure( L"Failed to create thread", E_FAIL );
    }

    return hr;
}

DUPL_RETURN CScrReader::ProcessFrame(_In_ FRAME_DATA* Data, INT OffsetX, INT OffsetY, _In_ DXGI_OUTPUT_DESC* DeskDesc )
{
    DUPL_RETURN Ret = DUPL_RETURN_SUCCESS;
	WCHAR dstr[512];

    // Process dirties and moves
    if (Data->FrameInfo.TotalMetadataBufferSize)
    {
        D3D11_TEXTURE2D_DESC Desc;
        Data->Frame->GetDesc(&Desc);
		/*
		printf("%d %d %d %d %d\n",Desc.Width,Desc.Height,Desc.Format,Desc.MipLevels,Desc.MiscFlags);
		CopyDirty32to24(Data->Frame);
		SaveBitmap(Desc.Width,Desc.Height,(char*)m_pscreen);
		return Ret;
		*/
        if (Data->MoveCount)
        {
			//enumerate moved rectangles
			wsprintf(dstr,L"Moved %d:\n", Data->MoveCount );
			OutputDebugString(dstr);
			DXGI_OUTDUPL_MOVE_RECT* pMRects = reinterpret_cast<DXGI_OUTDUPL_MOVE_RECT*>(Data->MetaData);
			for( unsigned int i=0; i<Data->MoveCount; i++ )
			{
				wsprintf(dstr,L"  rect %d %d %d %d from %d %d\n", 
					pMRects[i].DestinationRect.left, 
					pMRects[i].DestinationRect.top, 
					pMRects[i].DestinationRect.right, 
					pMRects[i].DestinationRect.bottom,
					pMRects[i].SourcePoint.x,
					pMRects[i].SourcePoint.y 
					);
				OutputDebugString(dstr);
				//wprintf(dstr);
				CopyDirtyRect32to16( Data->Frame, &pMRects[i].DestinationRect );
			}
            if (Ret != DUPL_RETURN_SUCCESS)
            {
                return Ret;
            }
        }

        if (Data->DirtyCount)
        {
			//enumerate dirty rectangles
			wsprintf(dstr,L"Dirtyes %d:\n", Data->DirtyCount );
			OutputDebugString(dstr);
			RECT* pRects = reinterpret_cast<RECT*>(Data->MetaData + (Data->MoveCount * sizeof(DXGI_OUTDUPL_MOVE_RECT)));
			for( unsigned int i=0; i<Data->DirtyCount; i++ )
			{
				wsprintf(dstr,L"  rect %d %d %d %d\n", pRects[i].left, pRects[i].top, pRects[i].right, pRects[i].bottom );
				OutputDebugString(dstr);
				//wprintf(dstr);
				CopyDirtyRect32to16( Data->Frame, &pRects[i] );
			}
            if (Ret != DUPL_RETURN_SUCCESS)
            {
                return Ret;
            }
        }
    }
    return Ret;
}

DUPL_RETURN CScrReader::ProcessFailure(_In_ LPCWSTR Str, HRESULT hr )
{
	OutputDebugString(Str);
	wprintf(L"%s\n",Str);
	if( hr==S_OK )
		return DUPL_RETURN_SUCCESS;
	else
		return DUPL_RETURN_ERROR_UNEXPECTED;
}
