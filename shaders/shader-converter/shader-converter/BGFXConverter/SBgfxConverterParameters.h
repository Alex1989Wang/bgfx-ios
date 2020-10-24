//
//  SBgfxConverterParameters.h
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 编译shader的参数类，负责在编译的时候提供命令所需的各种参数 **/
@interface SBgfxConverterParameters : NSObject

/** 要编译的shader文件路径，对应编译命令中的-f 参数 **/
@property (nonatomic, strong) NSString *inputFilePath;

/** 编译shader需要的def文件的路径，对应编译命令中的-varyingdef 参数 **/
@property (nonatomic, strong) NSString *defFilePath;

/** 输出路径，对应编译命令中的-o 参数 **/
@property (nonatomic, strong) NSString *outputFilePath;

/** bgfx库中的src目录路径，对应编译命令中的-i 参数 **/
@property (nonatomic, strong) NSString *bgfxSrcPath;

/** 编译平台，对应编译命令中的--platform 参数 **/
@property (nonatomic, strong) NSString *platform;

/** 针对平台要编译出的shader模型，对应编译命令中的--p 参数 **/
@property (nonatomic, strong) NSString *shaderModel;

/** 编译的shader类型(顶点/片元)，对应编译命令中的--type 参数 **/
@property (nonatomic, strong) NSString *shaderType;

/** 编译优化选项，对应编译命令中的-O 参数，默认值为3 **/
@property (nonatomic, strong) NSString *optimizeLevel;

/**
 *
 *  @date           2018-10-24
 *  @author         Wall-E
 *  @description    组建执行编译shader命令所需要的参数数组
 *
 *  @return         NSArray         参数数组@[-f, xxxx, -o, xxx, -depends, -i, xxxx]
 *
 **/
- (NSArray<NSString *> *)setupCompileParamArray;


@end

NS_ASSUME_NONNULL_END
