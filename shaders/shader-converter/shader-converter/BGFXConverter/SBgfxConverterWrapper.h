//
//  SBgfxConverterWrapper.h
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import <Foundation/Foundation.h>

@class SBgfxConverterParameters;
NS_ASSUME_NONNULL_BEGIN

/** shader编译类，负责组建执行编译shader的命令需要的各种参数，执行编译shader的命令编译出shader **/
@interface SBgfxConverterWrapper : NSObject

@property (nonatomic, copy) NSString *bgfxShaderCToolPath;

/**
 *
 *  @date           2018-10-24
 *  @author         Wall-E
 *  @description    编译一个shader
 *
 *  @param          compileParam        编译shader用到的参数对象
 *  @param          needLog             是否输出转换日志
 *
 *  @return         BOOL                编译是否成功
 *
 **/
- (BOOL)compileShaderWithParam:(SBgfxConverterParameters *)compileParam needLog:(BOOL)needLog;

@end

NS_ASSUME_NONNULL_END
