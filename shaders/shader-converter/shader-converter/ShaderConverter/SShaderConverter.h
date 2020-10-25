//
//  SShaderConverter.h
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, emShaderCompilePlatform) {
    emShaderCompilePlatformNone = 0,
    emShaderCompilePlatformMetal = 1 << 0,
    emShaderCompilePlatformGlsl = 1 << 1
};

/** 编译shader的流程，负责读取目录、组建参数对象，调用编译方法 **/
@interface SShaderConverter : NSObject

@property (nonatomic, assign) BOOL isRelease;//默认是debug

@property (nonatomic, copy) NSString *bgfxShaderCToolPath;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithShaderFolderPath:(NSString *)shaderRootFolderPath NS_DESIGNATED_INITIALIZER;

- (void)setConvertTargetPlatforms:(NSArray<NSString *> *)platforms;

- (void)startConvertWithLog:(BOOL)needLog;

@end

NS_ASSUME_NONNULL_END
