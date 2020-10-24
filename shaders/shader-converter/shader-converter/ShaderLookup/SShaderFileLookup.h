//
//  SShaderFileLookup.h
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** shader文件管理器，负责处理查找文件、筛选文件等涉及文件管理的业务 **/
@interface SShaderFileLookup : NSObject

@property(nonatomic, strong, readonly) NSString *mainShaderFilePath;

@property(nonatomic, strong, readonly) NSString *mDefaultVertexFilePath;

@property(nonatomic, strong, readonly) NSString *mDefaultDefineFilePath;

/**
 *
 *  @date           2018-10-24
 *  @author         Wall-E
 *  @description    默认初始化器，用shader文件的主目录来初始化文件管理器
 *
 *  @param          mainShaderFilePath           shader文件的主目录，目录中包含bgfx目录及各平台的输出目录(如果没有则在运行中建立)
 *
 *  @return         PGShaderCompileFileManager   对象实例
 *
 **/
- (instancetype)initWithMainShaderFilePath:(NSString *)mainShaderFilePath NS_DESIGNATED_INITIALIZER;

/**
 *
 *  @date           2018-10-24
 *  @author         Wall-E
 *  @description    获取目录下的bgfx目录中的所有片元着色器文件
 *
 *  @return         NSArray<NSString *>         目录下所有片元着色器文件的相对路径(即不包含mainShaderFilePath)
 *
 **/
- (NSArray<NSString *> *)getAllFragmentFile;

/**
 *
 *  @date           2018-10-24
 *  @author         Wall-E
 *  @description    根据片元着色器的文件名查找并返回顶点着色器，并告知调用方是不是使用的默认顶点着色器
 *
 *  @param          fragmentFilePath            片元着色器文件路径
 *  @param          isDefaultFile               BOOL类型的指针，告知外部是不是使用的默认顶点着色器
 *
 *  @return         NSString *                  顶点着色器文件的绝对路径
 *
 **/
- (NSString *)getVertexFileWithFragmentFile:(NSString *)fragmentFilePath isDefaultVertexFile:(BOOL *)isDefaultFile;

/**
 *
 *  @date           2018-10-24
 *  @author         Wall-E
 *  @description    根据片元着色器的文件名查找并返回定义文件路径，并告知调用方是不是使用的默认顶点着色器
 *
 *  @param          fragmentFilePath            片元着色器文件路径
 *  @param          isDefaultFile               BOOL类型的指针，告知外部是不是使用的默认顶点着色器
 *
 *  @return         NSString *                  顶点着色器文件的绝对路径
 *
 **/
- (NSString *)getDefineFileWithFragmentFile:(NSString *)fragmentFilePath isDefaultDefineFile:(BOOL *)isDefaultFile;

- (NSString *)getFragmentFileWithFragmentFile:(NSString *)fragmentFilePath;


- (NSString *)getDefaultVertexShaderPath:(NSString *)platform;

/**
 *
 *  @date           2018-10-24
 *  @author         Wall-E
 *  @description    从shader文件的路径中把shader的文件名给解析出来
 *
 *  @param          shaderFilePath     shader文件的路径
 *
 *  @return         NSString           shader的文件名
 *
 **/
- (NSString *)getShaderFileName:(NSString *)shaderFilePath;

/**
 *
 *  @date           2018-10-24
 *  @author         Wall-E
 *  @description    组建编译shader的输出目录
 *                  根据片元着色器文件路径，替换到平台，得到指定平台的输出目录
 *                  如果没有创建该目录，则创建，如果已经创建了，那么直接返回
 *
 *  @param          filePath                    片元着色器文件的相对路径
 *  @param          platform                    编译平台
 *
 *  @return         NSString                    编译shader的输出目录绝对路径
 *
 **/
- (NSString *)setupCompileOutputDirectory:(NSString *)filePath andPlatform:(NSString *)platform withIsRelease:(BOOL) isRelease;

/**
 *
 *  @date           2018-10-24
 *  @author         Wall-E
 *  @description    组建编译shader的输出路径
 *                  将shader名称
 *
 *  @param          outputDir           shader的输出目录
 *  @param          fileName            shader名称
 *
 *  @return         NSString            编译shader的输出路径(带有文件名和后缀的绝对路径)
 *
 **/
- (NSString *)setupCompileOutputPath:(NSString *)outputDir andShaderFileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
