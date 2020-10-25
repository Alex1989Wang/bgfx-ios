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
        NSLog(@"Shader main Path: %@", shaderRootPath);;
        
        // the target renderer type
        NSString *type = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
        
        //shadercRelease
        NSString *bgfxShaderC = [NSString stringWithCString:argv[3] encoding:NSUTF8StringEncoding];

        // 转换器
        SShaderConverter *converter = [[SShaderConverter alloc] initWithShaderFolderPath:shaderRootPath];
        converter.bgfxShaderCToolPath = bgfxShaderC;
        converter.isRelease = NO;
        
        BOOL needToLog = YES;
        if (type.length) {
            NSArray<NSString *> *platforms = [type componentsSeparatedByString:@","];
            NSMutableArray<NSString *> *platformArr = [[NSMutableArray alloc] init];
            if ([platforms containsObject:@"metal"]) {
                [platformArr addObject:@"metal,ios,metal,metal"];
            }
            if ([platforms containsObject:@"opengl"]) {
                [platformArr addObject:@"glsl,linux,120,120"];
            }
            [converter setConvertTargetPlatforms:platformArr];
            NSLog(@"converting platforms: %@", platformArr);
        }
        [converter startConvertWithLog:needToLog];
    }
    
    return 0;
}
