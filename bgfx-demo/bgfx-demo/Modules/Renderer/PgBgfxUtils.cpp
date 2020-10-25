//
//  PgBgfxUtils.cpp
//  PgImageAlgoResManager
//
//  Created by Camera360 on 2018/10/30.
//  Copyright © 2018 vstudio. All rights reserved.
//

#include "PgBgfxUtils.hpp"

#include <bgfx/bgfx.h>

#include <bx/readerwriter.h>
#include <bx/math.h>

#include <bimg/decode.h>

//#include <WebP/decode.h>

//#include "dbg.h"

//#include "ShaderSecurityUtil.hpp"
#include "PgEntry.hpp"
//#include "sdkLog.h"

#include <string>
#include <fstream>
#include <iostream>

void * load(bx::FileReaderI *_reader, bx::AllocatorI *_allocator, const char *_filePath, uint32_t *_size) {
    if (bx::open(_reader, _filePath)) {
        uint32_t size = (uint32_t) bx::getSize(_reader);
        void *data = BX_ALLOC(_allocator, size);
        bx::read(_reader, data, size);
        bx::close(_reader);
        if (NULL != _size) {
            *_size = size;
        }
        return data;
    } else {
//        DBG("Failed to open: %s.", _filePath);
    }

    if (NULL != _size) {
        *_size = 0;
    }

    return NULL;
}

void *load(const char *_filePath, uint32_t *_size) {
    return load(entry::getFileReader(), entry::getAllocator(), _filePath, _size);
}

void unload(void *_ptr) {
    BX_FREE(entry::getAllocator(), _ptr);
}

float maxGPUTextureSize()
{
    return (float)bgfx::getCaps()->limits.maxTextureSize;
}

static const bgfx::Memory *loadMem(bx::FileReaderI *_reader, const char *_filePath) {
    std::string tempFilePath = _filePath;
    std::string endTagStr = ".vs";
    std::string endTaOtherStr = ".fs";
    //如果shader是以.vs和.fs结尾就是未加密shader
//    if(endTagStr == tempFilePath.substr(tempFilePath.length() - endTagStr.length(), endTagStr.length()) || endTaOtherStr == tempFilePath.substr(tempFilePath.length() - endTaOtherStr.length(), endTaOtherStr.length())){
        
        if (bx::open(_reader, _filePath)) {
            uint32_t size = (uint32_t) bx::getSize(_reader);
            const bgfx::Memory *mem = bgfx::alloc(size + 1);
            bx::read(_reader, mem->data, size);
            bx::close(_reader);
            mem->data[mem->size - 1] = '\0';
            return mem;
        }
//    }
//    else
//    {
//        std::cout << "是加密后字符串" << _filePath << std::endl;
//        ShaderSecurityUtil * securityUtil = new ShaderSecurityUtil();
//        unsigned char * encodeChar = securityUtil->decryptFileWithName(_filePath);
//        if (encodeChar == NULL) {
//            std::cout << "是加密后字符串，崩溃！！！" << _filePath << std::endl;
//        }
//        const bgfx::Memory *mem = bgfx::copy(encodeChar, securityUtil->iLen);
//        mem->data[mem->size - 1] = '\0';
//        delete securityUtil;
//        return mem;
//    }
//    DBG("Failed to load %s.", _filePath);
    return NULL;
}

static void *loadMem(bx::FileReaderI *_reader, bx::AllocatorI *_allocator, const char *_filePath,
                     uint32_t *_size) {
    if (bx::open(_reader, _filePath)) {
        uint32_t size = (uint32_t) bx::getSize(_reader);
        void *data = BX_ALLOC(_allocator, size);
        bx::read(_reader, data, size);
        bx::close(_reader);

        if (NULL != _size) {
            *_size = size;
        }
        return data;
    }

//    DBG("Failed to load %s.", _filePath);
    return NULL;
}

static bgfx::ShaderHandle loadShader(bx::FileReaderI *_reader, const char *_name) {
    bgfx::ShaderHandle handle = bgfx::createShader(loadMem(_reader, _name));
    bgfx::setName(handle, _name);

    return handle;
}

bgfx::ShaderHandle loadShader(const char *_name) {
    return loadShader(entry::getFileReader(), _name);
}

bgfx::ProgramHandle
loadProgram(bx::FileReaderI *_reader, const char *_vsName, const char *_fsName) {
    bgfx::ShaderHandle vsh = loadShader(_reader, _vsName);
    bgfx::ShaderHandle fsh = BGFX_INVALID_HANDLE;
    if (NULL != _fsName) {
        fsh = loadShader(_reader, _fsName);
    }

    return bgfx::createProgram(vsh, fsh, true /* destroy shaders when program is destroyed */);
}

bgfx::ProgramHandle loadProgram(const char *_vsName, const char *_fsName) {
    return loadProgram(entry::getFileReader(), _vsName, _fsName);
}

static void imageReleaseCb(void *_ptr, void *_userData) {
    BX_UNUSED(_ptr);
    bimg::ImageContainer *imageContainer = (bimg::ImageContainer *) _userData;
    bimg::imageFree(imageContainer);
}

//static void imageReleaseWebp(void *_ptr, void *_userData) {
//    BX_UNUSED(_ptr);
//    WebPDecoderConfig *config = (WebPDecoderConfig *) _userData;
//    WebPFreeDecBuffer(&(config->output));
//    delete config;
//}

bgfx::TextureHandle loadTexture(bx::FileReaderI *_reader,
                                const char *_filePath,
                                uint64_t _flags,
                                uint8_t _skip,
                                bgfx::TextureInfo *_info,
                                bimg::Orientation::Enum *_orientation) {
    BX_UNUSED(_skip);
    bgfx::TextureHandle handle = BGFX_INVALID_HANDLE;

    uint32_t size;
    void *data = load(_reader, entry::getAllocator(), _filePath, &size);

    if (NULL != data) {
        bimg::ImageContainer *imageContainer = bimg::imageParse(entry::getAllocator(), data, size);
//        LOGD("loadTexture start  %s ",_filePath);
        //bimg::ImageContainer *imageContainer = bimg::imageParse(entry::getAllocator(), data, size,
                                                                //bimg::TextureFormat::Enum::RGBA8);
        
        if (NULL != imageContainer) {
            if (NULL != _orientation) {
                *_orientation = imageContainer->m_orientation;
            }

            const bgfx::Memory *mem = bgfx::makeRef(
                    imageContainer->m_data, imageContainer->m_size, imageReleaseCb, imageContainer
            );
            unload(data);
            if (imageContainer->m_cubeMap) {
                handle = bgfx::createTextureCube(
                        uint16_t(imageContainer->m_width), 1 < imageContainer->m_numMips,
                        imageContainer->m_numLayers,
                        bgfx::TextureFormat::Enum(imageContainer->m_format), _flags, mem
                );
            } else if (1 < imageContainer->m_depth) {
                handle = bgfx::createTexture3D(
                        uint16_t(imageContainer->m_width), uint16_t(imageContainer->m_height),
                        uint16_t(imageContainer->m_depth), 1 < imageContainer->m_numMips,
                        bgfx::TextureFormat::Enum(imageContainer->m_format), _flags, mem
                );
            } else if (bgfx::isTextureValid(0, false, imageContainer->m_numLayers,
                                            bgfx::TextureFormat::Enum(imageContainer->m_format),
                                            _flags)) {
                handle = bgfx::createTexture2D(
                        uint16_t(imageContainer->m_width), uint16_t(imageContainer->m_height),
                        1 < imageContainer->m_numMips, imageContainer->m_numLayers,
                        bgfx::TextureFormat::Enum(imageContainer->m_format), _flags, mem
                );
            }

            if (bgfx::isValid(handle)) {
                bgfx::setName(handle, _filePath);
            }
            if (NULL != _info) {
                bgfx::calcTextureSize(
                        *_info, uint16_t(imageContainer->m_width),
                        uint16_t(imageContainer->m_height), uint16_t(imageContainer->m_depth),
                        imageContainer->m_cubeMap, 1 < imageContainer->m_numMips,
                        imageContainer->m_numLayers,
                        bgfx::TextureFormat::Enum(imageContainer->m_format)
                );
            }
        }
//        LOGD("loadTexture end %s ",_filePath);

    }

    return handle;
}

std::tuple<const bgfx::Memory *, emTextureMemFormat> loadTexture(const char *_filePath,
                                                                 uint8_t _skip,
                                                                 bgfx::TextureInfo *_info,
                                                                 bimg::Orientation::Enum *_orientation) {
    bx::FileReaderI *_reader = entry::getFileReader();
    
    BX_UNUSED(_skip);
    
    uint32_t size;
    void *data = load(_reader, entry::getAllocator(), _filePath, &size);
    
    if (NULL != data)
    {
        bimg::ImageContainer *imageContainer = bimg::imageParse(entry::getAllocator(), data, size);
        
        // 如果是BGFX支持的图片格式(譬如jpg、png等等)，可以创建出bimg::ImageContainer对象
        if (NULL != imageContainer)
        {
            unload(data);
//            LOGD("loadTexture start  %s ",_filePath);
            if (NULL != _orientation)
            {
                *_orientation = imageContainer->m_orientation;
            }
            
            const bgfx::Memory *mem = bgfx::makeRef(imageContainer->m_data, imageContainer->m_size, imageReleaseCb, imageContainer);

            if (NULL != _info)
            {
                bgfx::calcTextureSize(*_info, uint16_t(imageContainer->m_width),
                                      uint16_t(imageContainer->m_height), uint16_t(imageContainer->m_depth),
                                      imageContainer->m_cubeMap, 1 < imageContainer->m_numMips,
                                      imageContainer->m_numLayers,
                                      bgfx::TextureFormat::Enum(imageContainer->m_format));
            }
//            LOGD("loadTexture end %s ",_filePath);
            return std::make_tuple(mem, emTextureMemFormatBGFXSupported);
        }
        // 如果无法创建出bimg::ImageContainer对象，那么考虑可能是webp数据，尝试使用libWebp解析，看能否解析出来。
//        else if (WebPGetInfo((const uint8_t *)data, (size_t)size, NULL, NULL))
//        {
//            WebPDecoderConfig * config = new WebPDecoderConfig();
//            if (!WebPInitDecoderConfig(config))
//            {
//                WebPFreeDecBuffer(&(config->output));
//                delete config;
//                return std::make_tuple(nullptr, emTextureMemFormatWebp);
//            }
//            config->options.no_fancy_upsampling = 1;
//            config->options.bypass_filtering = 1;
//            config->options.use_threads = 1;
//            // 如果这里指定了输出的色彩空间，那么libwebp会解析为指定的色彩空间
//            // 如果没有指定，那么就会按文件本身的色彩空间来。
//            config->output.colorspace = MODE_RGBA;
//            VP8StatusCode code = WebPDecode((const uint8_t *)data, size, config);
//            unload(data);
//            if (code == VP8_STATUS_OK)
//            {
//                _info->width = config->output.width;
//                _info->height = config->output.height;
//                _info->format = bgfx::TextureFormat::RGBA8;
//                _info->storageSize = (uint32_t)config->output.u.RGBA.size;
//                const bgfx::Memory *mem = bgfx::makeRef(config->output.u.RGBA.rgba,
//                                                        (uint32_t)config->output.u.RGBA.size, imageReleaseWebp, config);
//                if (NULL != mem)
//                {
//                    return std::make_tuple(mem, emTextureMemFormatWebp);
//                }
//                else
//                {
//                    WebPFreeDecBuffer(&(config->output));
//                    delete config;
//                }
//            }
//            else
//            {
//                WebPFreeDecBuffer(&(config->output));
//                delete config;
//            }
//        }
    }
    
    return std::make_tuple(nullptr, emTextureMemFormatUnknown);
}

bgfx::TextureHandle loadTexture(const char *_name,
                                uint64_t _flags,
                                uint8_t _skip,
                                bgfx::TextureInfo *_info,
                                bimg::Orientation::Enum *_orientation) {
    return loadTexture(entry::getFileReader(), _name, _flags, _skip, _info, _orientation);
}

bgfx::TextureHandle loadTextureFromData(const unsigned char *imageData, uint32_t width,
                                        uint32_t height,
                                        bgfx::TextureFormat::Enum format,
                                        uint64_t _flags, uint8_t _skip,
                                        bgfx::TextureInfo *_info,
                                        bimg::Orientation::Enum *_orientation) {

    bgfx::TextureHandle handle;
    // TODO 需要根据format来计算，临时只区分了BGRA格式和R8
    int multiple = 4;
    if (format == bgfx::TextureFormat::R8) {
        multiple = 1;
    }
    int size = width * height * multiple;

//    const bgfx::Memory *mem = bgfx::makeRef(imageData, size, NULL, NULL);
    const bgfx::Memory *mem = bgfx::copy(imageData, size);
    handle = bgfx::createTexture2D(uint16_t(width), uint16_t(height), false, 1, format, _flags, mem);

    return handle;
}

void updateTextureData(bgfx::TextureHandle _handle,
                       uint16_t _layer, uint8_t _mip, uint16_t _x,
                       uint16_t _y, uint16_t _width, uint16_t _height,
                       const unsigned char *imageData,
                       uint16_t _pitch)
{
    int size = _width * _height * 4;
    const bgfx::Memory *mem = bgfx::makeRef(imageData, size, NULL, NULL);
    bgfx::updateTexture2D(_handle, _layer, _mip, _x, _y, _width, _height, mem, _pitch);
}

bgfx::TextureHandle loadTextureFromData(const bgfx::Memory *mem, uint32_t width,
                                        uint32_t height,
                                        bgfx::TextureFormat::Enum format,
                                        uint64_t _flags, uint8_t _skip,
                                        bgfx::TextureInfo *_info,
                                        bimg::Orientation::Enum *_orientation)
{
    bgfx::TextureHandle handle;
    // TODO 需要根据format来计算，临时使用BGRA格式
//    int size = width * height * 4;
//    const bgfx::Memory *mem = bgfx::makeRef(imageData, size, NULL, NULL);
    //const bgfx::Memory *mem = bgfx::copy(imageData, width*height*4);
    handle = bgfx::createTexture2D(uint16_t(width), uint16_t(height), false, 1, format, _flags, mem);

    return handle;
}

bimg::ImageContainer *imageLoad(const char *_filePath, bgfx::TextureFormat::Enum _dstFormat) {
    uint32_t size = 0;
    void *data = loadMem(entry::getFileReader(), entry::getAllocator(), _filePath, &size);

    return bimg::imageParse(entry::getAllocator(), data, size,
                            bimg::TextureFormat::Enum(_dstFormat));
}

void calcTangents(void *_vertices, uint16_t _numVertices, bgfx::VertexLayout _decl,
                  const uint16_t *_indices, uint32_t _numIndices) {
    struct PosTexcoord {
        float m_x;
        float m_y;
        float m_z;
        float m_pad0;
        float m_u;
        float m_v;
        float m_pad1;
        float m_pad2;
    };

    float *tangents = new float[6 * _numVertices];
    bx::memSet(tangents, 0, 6 * _numVertices * sizeof(float));

    PosTexcoord v0;
    PosTexcoord v1;
    PosTexcoord v2;

    for (uint32_t ii = 0, num = _numIndices / 3; ii < num; ++ii) {
        const uint16_t *indices = &_indices[ii * 3];
        uint32_t i0 = indices[0];
        uint32_t i1 = indices[1];
        uint32_t i2 = indices[2];

        bgfx::vertexUnpack(&v0.m_x, bgfx::Attrib::Position, _decl, _vertices, i0);
        bgfx::vertexUnpack(&v0.m_u, bgfx::Attrib::TexCoord0, _decl, _vertices, i0);

        bgfx::vertexUnpack(&v1.m_x, bgfx::Attrib::Position, _decl, _vertices, i1);
        bgfx::vertexUnpack(&v1.m_u, bgfx::Attrib::TexCoord0, _decl, _vertices, i1);

        bgfx::vertexUnpack(&v2.m_x, bgfx::Attrib::Position, _decl, _vertices, i2);
        bgfx::vertexUnpack(&v2.m_u, bgfx::Attrib::TexCoord0, _decl, _vertices, i2);

        const float bax = v1.m_x - v0.m_x;
        const float bay = v1.m_y - v0.m_y;
        const float baz = v1.m_z - v0.m_z;
        const float bau = v1.m_u - v0.m_u;
        const float bav = v1.m_v - v0.m_v;

        const float cax = v2.m_x - v0.m_x;
        const float cay = v2.m_y - v0.m_y;
        const float caz = v2.m_z - v0.m_z;
        const float cau = v2.m_u - v0.m_u;
        const float cav = v2.m_v - v0.m_v;

        const float det = (bau * cav - bav * cau);
        const float invDet = 1.0f / det;

        const float tx = (bax * cav - cax * bav) * invDet;
        const float ty = (bay * cav - cay * bav) * invDet;
        const float tz = (baz * cav - caz * bav) * invDet;

        const float bx = (cax * bau - bax * cau) * invDet;
        const float by = (cay * bau - bay * cau) * invDet;
        const float bz = (caz * bau - baz * cau) * invDet;

        for (uint32_t jj = 0; jj < 3; ++jj) {
            float *tanu = &tangents[indices[jj] * 6];
            float *tanv = &tanu[3];
            tanu[0] += tx;
            tanu[1] += ty;
            tanu[2] += tz;

            tanv[0] += bx;
            tanv[1] += by;
            tanv[2] += bz;
        }
    }
    for (uint32_t ii = 0; ii < _numVertices; ++ii)
    {
        const bx::Vec3 tanu = bx::load<bx::Vec3>(&tangents[ii*6]);
        const bx::Vec3 tanv = bx::load<bx::Vec3>(&tangents[ii*6 + 3]);
        
        float nxyzw[4];
        bgfx::vertexUnpack(nxyzw, bgfx::Attrib::Normal, _decl, _vertices, ii);
        
        const bx::Vec3 normal  = bx::load<bx::Vec3>(nxyzw);
        const float    ndt     = bx::dot(normal, tanu);
        const bx::Vec3 nxt     = bx::cross(normal, tanu);
        const bx::Vec3 tmp     = bx::sub(tanu, bx::mul(normal, ndt) );
        
        float tangent[4];
        bx::store(tangent, bx::normalize(tmp) );
        tangent[3] = bx::dot(nxt, tanv) < 0.0f ? -1.0f : 1.0f;
        
        bgfx::vertexPack(tangent, true, bgfx::Attrib::Tangent, _decl, _vertices, ii);
    }

    delete[] tangents;
}

namespace bgfx {
    int32_t read(bx::ReaderI *_reader, bgfx::VertexLayout &_decl, bx::Error *_err = NULL);
}

//Args::Args(int _argc, const char* const* _argv)
//: m_type(bgfx::RendererType::Count)
//, m_pciId(BGFX_PCI_ID_NONE)
//{
//    bx::CommandLine cmdLine(_argc, (const char**)_argv);
//    
//    if (cmdLine.hasArg("gl") )
//    {
//        m_type = bgfx::RendererType::OpenGL;
//    }
//    else if (cmdLine.hasArg("vk") )
//    {
//        m_type = bgfx::RendererType::Vulkan;
//    }
//    else if (cmdLine.hasArg("noop") )
//    {
//        m_type = bgfx::RendererType::Noop;
//    }
//    else if (BX_ENABLED(BX_PLATFORM_WINDOWS|BX_PLATFORM_WINRT|BX_PLATFORM_XBOXONE) )
//    {
//        if (cmdLine.hasArg("d3d9") )
//        {
//            m_type = bgfx::RendererType::Direct3D9;
//        }
//        else if (cmdLine.hasArg("d3d11") )
//        {
//            m_type = bgfx::RendererType::Direct3D11;
//        }
//        else if (cmdLine.hasArg("d3d12") )
//        {
//            m_type = bgfx::RendererType::Direct3D12;
//        }
//    }
//    else if (BX_ENABLED(BX_PLATFORM_OSX) )
//    {
//        if (cmdLine.hasArg("mtl") )
//        {
//            m_type = bgfx::RendererType::Metal;
//        }
//    }
//    
//    if (cmdLine.hasArg("amd") )
//    {
//        m_pciId = BGFX_PCI_ID_AMD;
//    }
//    else if (cmdLine.hasArg("nvidia") )
//    {
//        m_pciId = BGFX_PCI_ID_NVIDIA;
//    }
//    else if (cmdLine.hasArg("intel") )
//    {
//        m_pciId = BGFX_PCI_ID_INTEL;
//    }
//    else if (cmdLine.hasArg("sw") )
//    {
//        m_pciId = BGFX_PCI_ID_SOFTWARE_RASTERIZER;
//    }
//}
