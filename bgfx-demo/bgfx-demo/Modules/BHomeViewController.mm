//
//  BHomeViewController.m
//  bgfx-demo
//
//  Created by 王江 on 2020/10/24.
//

#import "BHomeViewController.h"
#import "BRenderMetalView.h"
#include <bgfx/bgfx.h>
#include <bgfx/platform.h>
#include "PgBgfxUtils.hpp"

@interface BHomeViewController ()
@property (nonatomic, strong) BRenderMetalView *mtkView;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) CGSize renderSize;
@property (nonatomic, assign) bgfx::VertexBufferHandle m_vbh;
@property (nonatomic, assign) bgfx::IndexBufferHandle m_ibh;
@property (nonatomic, assign) bgfx::ProgramHandle m_program;
@property (nonatomic, assign) bgfx::VertexLayout m_layout;
@property (nonatomic, assign) bgfx::TextureHandle m_texture;
@property (nonatomic, assign) bgfx::UniformHandle m_textureInput;
@property (nonatomic, assign) bgfx::FrameBufferHandle m_fbh;
@end

struct VertexCoordTextureCoord {
    // vertex coordinates
    float m_x;
    float m_y;
    float m_z;
    // texture coordinates
    int16_t m_u;
    int16_t m_v;
    
};

static VertexCoordTextureCoord s_fbo_Vertices[] =
{
    {-1.0f,  1.0f,  0.0f,      0, 0x7fff},
    { 1.0f,  1.0f,  0.0f, 0x7fff, 0x7fff},
    {-1.0f, -1.0f,  0.0f,      0,      0},
    { 1.0f, -1.0f,  0.0f, 0x7fff,      0},
};

// 顶点绘制顺序
static const uint16_t s_TriList[] =
{
    0, 2, 1,
    1, 2, 3,
};


@implementation BHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.mtkView = [[BRenderMetalView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mtkView];
    self.mtkView.backgroundColor = [UIColor whiteColor];
    CGSize size = self.view.bounds.size;
    CGFloat scale = [UIScreen mainScreen].scale;
    self.renderSize = CGSizeMake(size.width * scale, size.height * scale);
    // bgfx
    [self initBgfx];
    // display
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayTicked)];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)initBgfx {
    // platform data
    bgfx::PlatformData pd;
    pd.nwh = (__bridge void *)self.mtkView.layer;
    pd.ndt = NULL;
    pd.backBuffer = NULL;
    pd.backBufferDS = NULL;
    bgfx::setPlatformData(pd);
    // init
    bgfx::Init init;
    init.type = bgfx::RendererType::Count;
    init.vendorId = 0;
    CGSize size = self.view.bounds.size;
    CGFloat scale = [UIScreen mainScreen].scale;
    init.resolution.width = size.width * scale;
    init.resolution.height = size.height * scale;
    init.resolution.reset = BGFX_RESET_VSYNC;
    init.allocator = NULL;
    init.callback = NULL;
    bgfx::init(init);
    // debug
#ifdef DEBUG
    bgfx::setDebug(BGFX_DEBUG_TEXT | BGFX_DEBUG_STATS);
#else
    bgfx::setDebug(BGFX_DEBUG_NONE);
#endif
    bgfx::setViewRect(0, 0, 0, init.resolution.width, init.resolution.height);
    bgfx::setState(BGFX_STATE_WRITE_RGB | BGFX_STATE_WRITE_A);
    bgfx::setViewClear(0, BGFX_CLEAR_COLOR|BGFX_CLEAR_DEPTH, 0xFF0000FF, 1.f, 0); //rgba
    bgfx::touch(0);
    
    // use shader
    self.m_layout = bgfx::VertexLayout();
    self.m_layout
    .begin()
    .add(bgfx::Attrib::Position, 3, bgfx::AttribType::Float)
    .add(bgfx::Attrib::TexCoord0, 2, bgfx::AttribType::Int16, true) //normalized
    .end();
    self.m_vbh = bgfx::createVertexBuffer(bgfx::makeRef(s_fbo_Vertices, sizeof(s_fbo_Vertices)), self.m_layout);
    self.m_ibh = bgfx::createIndexBuffer(bgfx::makeRef(s_TriList, sizeof(s_TriList)));
    NSString *shaderBundle = [[NSBundle mainBundle] pathForResource:@"output" ofType:@"bundle"];
    NSString *vsPath = [NSString stringWithFormat:@"%@/metal/common.vs", shaderBundle];
    NSString *fsPath = [NSString stringWithFormat:@"%@/metal/common.fs", shaderBundle];
    self.m_program = loadProgram([vsPath cStringUsingEncoding:NSUTF8StringEncoding], [fsPath cStringUsingEncoding:NSUTF8StringEncoding]);
    NSString *pngPath = [[NSBundle mainBundle] pathForResource:@"parallax-d" ofType:@"png"];
    bgfx::TextureHandle texture = loadTexture([pngPath cStringUsingEncoding:NSUTF8StringEncoding]);
    self.m_texture = texture;
    NSAssert(bgfx::isValid(self.m_texture), @"invalid handle");
    self.m_textureInput = bgfx::createUniform("common_texColor", bgfx::UniformType::Sampler);
    // 切记 bgfx 的 FBO 初始化要定义成BGFX_INVALID_HANDLE，不然要被坑
    bgfx::FrameBufferHandle m_fbh = BGFX_INVALID_HANDLE;
    // 不设置成BGFX_INVALID_HANDLE的话，这里第一次上来，isValid就会返回true
    if (!bgfx::isValid(m_fbh)) {
        self.m_fbh = bgfx::createFrameBuffer(size.width * scale, size.height * scale, bgfx::TextureFormat::Enum::BGRA8);
    }
}

#pragma MARK: display
- (void)displayTicked {
    // 渲染到屏幕的 view 需要主动将该 view 的 FBO 设置为 invalid，然后从 FBO 中拿出 attach 的纹理，设置到这次渲染需要的输入参数中,然后显示
    bgfx::setVertexBuffer(0, self.m_vbh);
    bgfx::setIndexBuffer(self.m_ibh);
    bgfx::setViewRect(0, 0, 0, self.renderSize.width, self.renderSize.height);
//    bgfx::setViewFrameBuffer(0, BGFX_INVALID_HANDLE);
    bgfx::setViewFrameBuffer(0, self.m_fbh);
    bgfx::setState(BGFX_STATE_WRITE_RGB|BGFX_STATE_WRITE_A);
    bgfx::setTexture(0, self.m_textureInput, self.m_texture);
    bgfx::submit(0, self.m_program);
    // 显示到屏幕
    bgfx::frame();
}

@end
