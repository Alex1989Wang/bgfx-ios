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

@interface BHomeViewController ()
@property (nonatomic, strong) BRenderMetalView *mtkView;
@property (nonatomic, strong) CADisplayLink *link;
@end



@implementation BHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.mtkView = [[BRenderMetalView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mtkView];
    self.mtkView.backgroundColor = [UIColor whiteColor];
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
}

#pragma MARK: display
- (void)displayTicked {
    bgfx::frame();
}

@end
