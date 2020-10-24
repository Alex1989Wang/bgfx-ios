//
//  main.m
//  shader-converter
//
//  Created by 王江 on 2020/10/24.
//

#import <Foundation/Foundation.h>
#include "SFolderConfigs.h"
#include "SShaderConverter.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        /*
         argv[0]: 获取需要转换的所有shaders的根目录
         argv[1]: 获取需要转换的shader的目标类型 metal, opengl
         argv[2]: bgfx提供的shadercRelease命令行工具的路径
         
         参靠scheme中输入参数的配置
         */
        if (argc != 4) {
            NSLog(@"Converter params not correct.");
            return 1;
        }
        // shaders的根目录
        NSString *shaderRootPath = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        SFolderConfigs *folders = [[SFolderConfigs alloc] initWithShaderRootPath:shaderRootPath];
        NSLog(@"Shader main Path: %@", folders.rootPath);;
        
        // 目标平台
        NSString *type = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
        
        //shadercRelease
        NSString *bgfxShaderC = [NSString stringWithCString:argv[3] encoding:NSUTF8StringEncoding];

        // 转换器
        SShaderConverter *converter =
        [[SShaderConverter alloc] initWithMainShaderFilePath:folders.rootPath
                                                    andBGFXSrcPath:folders.bgfxDependencyPath]; //给 -i的参数
        converter.bgfxShaderCToolPath = bgfxShaderC;
        converter.isRelease = NO;
        
        BOOL needToLog = YES;
        if (type.length) {
            NSMutableArray<NSString *> *platformArr = [[NSMutableArray alloc] init];
            if ([type isEqualToString:@"metal"]) {
                [platformArr addObject:@"metal,ios,metal,metal"];
            } else if ([type isEqualToString:@"opengl"]) {
                [platformArr addObject:@"glsl,linux,120,120"];
            }
            [converter setCompilePlatform:platformArr];
            NSLog(@"converting platforms: ", platformArr);
        }
        [converter startCompile:needToLog];
    }
    
    return 0;
}
