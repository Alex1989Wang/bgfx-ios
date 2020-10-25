//
//  PgBgfxUtils.h
//  PgImageAlgoResManager
//
//  Created by Camera360 on 2018/10/30.
//  Copyright © 2018 vstudio. All rights reserved.
//

#ifndef PgBgfxUtils_h
#define PgBgfxUtils_h

#include <stdio.h>
#include <tuple>

#include <bx/pixelformat.h>
#include <bgfx/bgfx.h>
#include <bimg/bimg.h>

typedef enum
{
    emTextureMemFormatUnknown = 0,
    emTextureMemFormatBGFXSupported,
    emTextureMemFormatWebp
} emTextureMemFormat;

///
void *load(const char *_filePath, uint32_t *_size = NULL);

///
void unload(void *_ptr);

/** 取得GPU能够处理的纹理的最长边 **/
float maxGPUTextureSize();

///
bgfx::ShaderHandle loadShader(const char *_name);

///
bgfx::ProgramHandle loadProgram(const char *_vsName, const char *_fsName);

///
bgfx::TextureHandle
loadTexture(const char *_name, uint64_t _flags = BGFX_SAMPLER_U_CLAMP | BGFX_SAMPLER_V_CLAMP | BGFX_TEXTURE_RT, uint8_t _skip = 0,
            bgfx::TextureInfo *_info = NULL, bimg::Orientation::Enum *_orientation = NULL);

bgfx::TextureHandle loadTextureFromData(const unsigned char *imageData, uint32_t width,
                                        uint32_t height,
                                        bgfx::TextureFormat::Enum format,
                                        uint64_t _flags = BGFX_SAMPLER_U_CLAMP | BGFX_SAMPLER_V_CLAMP | BGFX_TEXTURE_RT, uint8_t _skip = 0,
                                        bgfx::TextureInfo *_info = NULL,
                                        bimg::Orientation::Enum *_orientation = NULL);

bgfx::TextureHandle loadTextureFromData(const bgfx::Memory *mem, uint32_t width,
                                        uint32_t height,
                                        bgfx::TextureFormat::Enum format,
                                        uint64_t _flags = BGFX_SAMPLER_U_CLAMP | BGFX_SAMPLER_V_CLAMP | BGFX_TEXTURE_RT, uint8_t _skip = 0,
                                        bgfx::TextureInfo *_info = NULL,
                                        bimg::Orientation::Enum *_orientation = NULL);

void updateTextureData(
        bgfx::TextureHandle _handle
        , uint16_t _layer
        , uint8_t _mip
        , uint16_t _x
        , uint16_t _y
        , uint16_t _width
        , uint16_t _height
        , const unsigned char *imageData
        , uint16_t _pitch = UINT16_MAX
);

//const bgfx::Memory *loadTexture( const char *_filePath, uint8_t _skip,
//                                bgfx::TextureInfo *_info, bimg::Orientation::Enum *_orientation);

/**
 *
 *  @date           2019-10-16
 *  @author         Wall-E
 *  @description    从文件加载纹理数据，用于填充PgTexture对象
 *
 *  @param          _filePath            纹理数据文件绝对路径，用于直接从文件读取纹理数据
 *  @param          _skip               (暂时不清楚干啥的)
 *  @param          _info               纹理信息对象，用于记录纹理数据相关信息(譬如宽度、高度、数据格式等)
 *  @param          _orientation        引用，告知调用方加载的纹理数据的方向
 *
 *  @return         return type        add comment for return type
 *
 **/
std::tuple<const bgfx::Memory *, emTextureMemFormat> loadTexture(const char *_filePath,
                                                                 uint8_t _skip,
                                                                 bgfx::TextureInfo *_info,
                                                                 bimg::Orientation::Enum *_orientation);
///
bimg::ImageContainer *imageLoad(const char *_filePath, bgfx::TextureFormat::Enum _dstFormat);

///
void calcTangents(void *_vertices, uint16_t _numVertices, bgfx::VertexLayout _decl,
                  const uint16_t *_indices, uint32_t _numIndices);

/// Returns true if both internal transient index and vertex buffer have
/// enough space.
///
/// @param[in] _numVertices Number of vertices.
/// @param[in] _decl Vertex declaration.
/// @param[in] _numIndices Number of indices.
///
inline bool checkAvailTransientBuffers(uint32_t _numVertices, const bgfx::VertexLayout &_decl,
                                       uint32_t _numIndices) {
    return _numVertices == bgfx::getAvailTransientVertexBuffer(_numVertices, _decl)
           && (0 == _numIndices || _numIndices == bgfx::getAvailTransientIndexBuffer(_numIndices));
}

///
inline uint32_t encodeNormalRgba8(float _x, float _y = 0.0f, float _z = 0.0f, float _w = 0.0f) {
    const float src[] =
            {
                    _x * 0.5f + 0.5f,
                    _y * 0.5f + 0.5f,
                    _z * 0.5f + 0.5f,
                    _w * 0.5f + 0.5f,
            };
    uint32_t dst;
    bx::packRgba8(&dst, src);
    return dst;
}

///
struct MeshState {
    struct Texture {
        uint32_t m_flags;
        bgfx::UniformHandle m_sampler;
        bgfx::TextureHandle m_texture;
        uint8_t m_stage;
    };

    Texture m_textures[4];
    uint64_t m_state;
    bgfx::ProgramHandle m_program;
    uint8_t m_numTextures;
    bgfx::ViewId m_viewId;
};

struct Mesh;

///
Mesh *meshLoad(const char *_filePath);

///
void meshUnload(Mesh *_mesh);

///
MeshState *meshStateCreate();

///
void meshStateDestroy(MeshState *_meshState);

///
void
meshSubmit(const Mesh *_mesh, bgfx::ViewId _id, bgfx::ProgramHandle _program, const float *_mtx,
           uint64_t _state = BGFX_STATE_MASK);

///
void
meshSubmit(const Mesh *_mesh, const MeshState *const *_state, uint8_t _numPasses, const float *_mtx,
           uint16_t _numMatrices = 1);

///
struct Args {
    Args(int _argc, const char *const *_argv);

    bgfx::RendererType::Enum m_type;
    uint16_t m_pciId;
};

#endif /* PgBgfxUtils_h */
