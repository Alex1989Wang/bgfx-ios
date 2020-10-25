//
//  SShaderConverter.m
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import "SShaderConverter.h"
#import "SBgfxConverterWrapper.h"
#import "SFileMD5Generator.h"
#import "SShaderFileLookup.h"
#import "SBgfxConverterParameters.h"
#import "SFileMD5Generator.h"

typedef NS_OPTIONS(NSInteger, emShaderCompileOption) {
    emShaderCompileOptionNone = 0,
    emShaderCompileOptionVertex = 1 << 0,
    emShaderCompileOptionFragment = 1 << 1
};

@interface SShaderConverter()

@property(nonatomic, strong) SBgfxConverterWrapper *mBgfxConvter;

@property(nonatomic, strong) SShaderFileLookup *mFileManager;

@property(nonatomic, strong) NSMutableDictionary *md5Dic;

@property(nonatomic, strong) NSArray<NSString *> *convertPlatforms;

@end

@implementation SShaderConverter

- (instancetype)initWithShaderFolderPath:(NSString *)shaderRootFolderPath {
    self = [super init];
    if (self) {
        _mFileManager = [[SShaderFileLookup alloc] initWithShaderFolderPath:shaderRootFolderPath];
        _mBgfxConvter = [[SBgfxConverterWrapper alloc] init];
    }
    return self;
}

- (void)setConvertTargetPlatforms:(NSArray<NSString *> *)platforms {
    _convertPlatforms = platforms;
}

- (void)startConvertWithLog:(BOOL)needLog {
    [self convert:needLog];
}

- (void)convert:(BOOL)needLog {
    NSLog(@"Start converting all shaders.");
    
    // get shader files
    NSDictionary<NSNumber *,NSArray<NSString *> *> *allShaderFileMap = [self.mFileManager getAllShaderFilesSubpaths];

    //每次转换的结果
    __block BOOL compileResult = YES;
    //统计总共转换的次数
    __block NSInteger compileFSCount = 0;
    __block NSInteger compileVSCount = 0;
    __block NSInteger noNeedCompileCount = 0;
    __block NSInteger useDefaultShaderVCCount = 0;
    NSMutableArray<NSString *> *failedShaderArr = [[NSMutableArray alloc] init];
    
    for (NSNumber *type in @[@(emShaderCompileTypeVertex), @(emShaderCompileTypeFragment)]) {
        NSArray<NSString *> *shaderSubpaths = allShaderFileMap[type];
        emShaderCompileType sType = (emShaderCompileType)[type integerValue];
        [shaderSubpaths enumerateObjectsUsingBlock:^(NSString * _Nonnull shaderRelativePath, NSUInteger idx, BOOL * _Nonnull stop) {
            /** 判断是否需要重要编译，以及需要编译哪些shader **/
            emShaderCompileOption compileType = [self decideShaderCompileType:shaderRelativePath];
            if (compileType == emShaderCompileOptionNone) {
                NSLog(@"No change for shader %@", shaderRelativePath);
                noNeedCompileCount++;
                return;
            }
           
            // fragment
            switch (sType) {
                case emShaderCompileTypeFragment: {
                    /** 获取片元着色器文件绝对路径 **/
                    NSString *fragmentFilePath = [self.mFileManager getFragmentFileWithFragmentFile:shaderRelativePath];
                    /** 获取define文件的绝对路径 **/
                    BOOL isDefaultDefFile = NO;
                    NSString *defFilePath = [self.mFileManager getDefineFileWithFragmentFile:shaderRelativePath
                                                                         isDefaultDefineFile:&isDefaultDefFile];
                    // no need to convert
                    if (!(compileType & emShaderCompileTypeFragment)) { break; }
                    [self.convertPlatforms enumerateObjectsUsingBlock:^(NSString *platformInfo, NSUInteger idx, BOOL *stop) {
                        /** 编译片元着色器 **/
                        compileFSCount++;
                        NSString *compileOutputPath = [self convertShader:shaderRelativePath
                                                           shaderFilePath:fragmentFilePath
                                                              defFilePath:defFilePath
                                                              compileType:emShaderCompileTypeFragment
                                                                 platform:platformInfo
                                                             shaderSuffix:@"fs"
                                                               andNeedLog:needLog];
                        compileResult = compileOutputPath != nil;
                        if (!compileResult)
                        {
                            NSAssert(NO, @"%@-%@转换失败", shaderRelativePath, platformInfo);
                            [failedShaderArr addObject:[NSString stringWithFormat:@"%@-%@", shaderRelativePath, platformInfo]];
                        }
                    }];
                    if (compileResult)
                    {
                        //既然编译成功了，那么就需要做MD5缓存，方便下次判断是否需要重新编译。
                        //为了简化流程，不去判断到底该缓存什么，这里简单粗暴地处理：只要不是公用的存def和vertex，不论是否有变化，都直接缓存。
                        /** 获取define文件的相对路径(相对于bgfx始) **/
                        if (!isDefaultDefFile)
                        {
                            [self cacheCompiledShader:defFilePath];
                        }
                        [self cacheCompiledShader:fragmentFilePath];
                        
                    }
                    break;
                }
                case emShaderCompileTypeVertex: {
                    BOOL isDefaultVertextFile = NO;
                    /** 获取顶点着色器文件绝对路径 **/
                    NSString *vertexFilePath = [self.mFileManager getVertexFileWithFragmentFile:shaderRelativePath
                                                                            isDefaultVertexFile:&isDefaultVertextFile];
                    /** 获取define文件的绝对路径 **/
                    BOOL isDefaultDefFile = NO;
                    NSString *defFilePath = [self.mFileManager getDefineFileWithFragmentFile:shaderRelativePath
                                                                         isDefaultDefineFile:&isDefaultDefFile];
                    //判断是否需要编译顶点着色器
                    if (!(compileType & emShaderCompileTypeVertex)) { break; }
                    [self.convertPlatforms enumerateObjectsUsingBlock:^(NSString *platformInfo, NSUInteger idx, BOOL *stop) {
                        /** 编译顶点着色器 **/
                        compileVSCount++;
                        NSString *compileOutputPath = [self convertShader:shaderRelativePath
                                                           shaderFilePath:vertexFilePath
                                                              defFilePath:defFilePath
                                                              compileType:emShaderCompileTypeVertex
                                                                 platform:platformInfo
                                                             shaderSuffix:@"vs"
                                                               andNeedLog:needLog];
                        
                        compileResult = compileOutputPath != nil;
                        if (!compileResult) {
                            NSAssert(NO, @"%@-%@转换失败", shaderRelativePath, platformInfo);
                            [failedShaderArr addObject:[NSString stringWithFormat:@"%@-%@", shaderRelativePath, platformInfo]];
                        }
                    }];
                    if (compileResult)
                    {
                        //既然编译成功了，那么就需要做MD5缓存，方便下次判断是否需要重新编译。
                        //为了简化流程，不去判断到底该缓存什么，这里简单粗暴地处理：只要不是公用的存def和vertex，不论是否有变化，都直接缓存。
                        /** 获取define文件的相对路径(相对于bgfx始) **/
                        if (!isDefaultDefFile) {
                            [self cacheCompiledShader:defFilePath];
                        }
                        [self cacheCompiledShader:vertexFilePath];
                    }
                    break;
                }
                default:
                    break;
            }
        }];
    }

    //最后把更新了的cache写入到UserDefault中
    [self saveshaderFileMD5Cache];
    
    NSLog(@"======================");
    NSLog(@"转换结束，共计处理了%ld个",compileFSCount+compileVSCount+useDefaultShaderVCCount+noNeedCompileCount);
    NSLog(@"其中真实转换了%ld个：shader.fs %ld个，shader.vs %ld个",compileFSCount+compileVSCount,compileFSCount,compileVSCount);
    NSLog(@"使用公用shader.vs %ld个，因cache而跳过%ld个",(long)useDefaultShaderVCCount, (long)noNeedCompileCount);
    NSLog(@"失败了%lu个，列举如下：",(unsigned long)[failedShaderArr count]);
    NSLog(@"%@", failedShaderArr);
    NSLog(@"======================");
}

#pragma mark - 内部方法
- (NSString *)generateShaderCompileOutputPath:(NSString *)shaderFileRelativePath platformInfo:(NSString *)platform shaderSuffix:(NSString *)suffix
{
    NSString *shaderName = [self.mFileManager getShaderFileName:shaderFileRelativePath];
    NSString *outputDir = [self.mFileManager setupShaderOutputDirectory:shaderFileRelativePath
                                                             withPlatform:platform
                                                           isRelease:self.isRelease];
    NSString *shaderFileName = [shaderName stringByAppendingPathExtension:suffix];
    NSString *shaderOutputPath = [self.mFileManager setupCompileOutputPath:outputDir
                                                         andShaderFileName:shaderFileName];
    return shaderOutputPath;
}

- (NSString *)convertShader:(NSString *)shaderRelativePath
             shaderFilePath:(NSString *)shaderFilePath
                defFilePath:(NSString *)defFilePath
                compileType:(emShaderCompileType)type
                   platform:(NSString *)platformInfo
               shaderSuffix:(NSString *)suffix
                 andNeedLog:(BOOL)needLog
{
    NSString *platform = [[platformInfo componentsSeparatedByString:@","] firstObject];
    NSString *outputPath = [self generateShaderCompileOutputPath:shaderRelativePath platformInfo:platform shaderSuffix:suffix];

    NSLog(@"=======================================================");
    NSLog(@"shader转换平台: %@", platform);
    NSLog(@"shader输入目录: %@", shaderFilePath);
    NSLog(@"define输入目录: %@", defFilePath);
    NSLog(@"shader输出目录: %@", outputPath);
    BOOL compileResult = [self compileShader:type
                              shaderFilePath:shaderFilePath
                                 defFilePath:defFilePath
                                    platform:platformInfo
                                  outputPath:outputPath
                                  andNeedLog:needLog];
    return compileResult ? outputPath : nil;
}

- (BOOL)compileShader:(emShaderCompileType)shaderType
       shaderFilePath:(NSString *)shaderFilePath
          defFilePath:(NSString *)defFilePath
             platform:(NSString *)platform
           outputPath:(NSString *)outputPath
           andNeedLog:(BOOL)needToLog
{
    SBgfxConverterParameters *compileParam = [[SBgfxConverterParameters alloc] init];
    [compileParam setShaderType:shaderType == emShaderCompileTypeVertex ? @"vertex" : @"fragment"];
    
    [compileParam setInputFilePath:shaderFilePath];
    [compileParam setOutputFilePath:outputPath];
    NSLog(@"outputPath: %@\n 转换前路径：%@", outputPath, shaderFilePath);
    [compileParam setDefFilePath:defFilePath];
    
    [compileParam setBgfxSrcPath:self.mFileManager.bgfxDependencyPath];
    
    NSArray<NSString *> *platformInfo = [platform componentsSeparatedByString:@","];
    [compileParam setPlatform:platformInfo[1]];
    NSString *shaderModel = shaderType == emShaderCompileTypeVertex ? platformInfo[2] : platformInfo[3];
    [compileParam setShaderModel:shaderModel ? shaderModel : @""];

    self.mBgfxConvter.bgfxShaderCToolPath = self.bgfxShaderCToolPath;
    return [self.mBgfxConvter compileShaderWithParam:compileParam needLog:needToLog];
}

- (emShaderCompileOption)decideShaderCompileType:(NSString *)fragmentFilePath
{
    emShaderCompileOption compileOption = emShaderCompileOptionNone;

    BOOL isDefaultFile = NO;
    NSString *defineFilePath = [self.mFileManager getDefineFileWithFragmentFile:fragmentFilePath
                                                            isDefaultDefineFile:&isDefaultFile];
    if ([self isFileChanged:defineFilePath isDefaultFile:YES])
    {
        compileOption |= emShaderCompileOptionVertex;
        compileOption |= emShaderCompileOptionFragment;
    }
    else
    {
        NSString *vertexFilePath = [self.mFileManager getVertexFileWithFragmentFile:fragmentFilePath
                                                                isDefaultVertexFile:&isDefaultFile];
        if ([self isFileChanged:vertexFilePath isDefaultFile:isDefaultFile])
        {
            compileOption |= emShaderCompileOptionVertex;
        }
        
        fragmentFilePath = [self.mFileManager getFragmentFileWithFragmentFile:fragmentFilePath];
        if ([self isFileChanged:fragmentFilePath isDefaultFile:NO])
        {
            compileOption |= emShaderCompileOptionFragment;
        }
    }

    return compileOption;
}

- (BOOL)isFileChanged:(NSString *)filePath isDefaultFile:(BOOL)isDefault
{
    NSString *fileMD5 = [SFileMD5Generator generateMD5ForFileAtPath:filePath];
    
    NSString *cacheKey = [filePath lastPathComponent];
    NSString *cachedFileMD5 = self.md5Dic[cacheKey];
    
    BOOL fileChanged = ![cachedFileMD5 isEqualToString:fileMD5];
    
    if(isDefault)
    {
        return fileChanged;
    }
    else
    {
        //还需要判断是否存在现在编译环境需要的路径
        NSString *bundleStr = [NSString stringWithFormat:@"%@.bundle", @"output"];
        NSString *lastPath = [cacheKey stringByReplacingOccurrencesOfString:@"bgfx/" withString:@""];
        NSMutableArray<NSString *> *lastPathComposition = [[lastPath pathComponents] mutableCopy];
        [lastPathComposition enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //获取路径最后部分加密后的字符串组合
            lastPathComposition[idx] = obj;
        }];
        NSString *encodeLastPath = [NSString pathWithComponents:lastPathComposition];
        
        NSString *encodePlatformMetalStr = @"metal";
        NSString *currentMetalPath = [NSString stringWithFormat:@"%@/%@/%@/%@",_mFileManager.rootPath,bundleStr,encodePlatformMetalStr,encodeLastPath];
        BOOL isExistMetal = [[NSFileManager defaultManager] fileExistsAtPath:currentMetalPath];
        
        NSString *encodePlatformGlslStr = @"glsl";
        NSString *currentGlslPath = [NSString stringWithFormat:@"%@/%@/%@/%@",_mFileManager.rootPath,bundleStr,encodePlatformGlslStr,encodeLastPath];
        BOOL isExistGlsl = [[NSFileManager defaultManager] fileExistsAtPath:currentGlslPath];
        
        //只有bgfx本身没有改变&&当前环境需要的文件存在 = 没有改变
        if (fileChanged == NO && (isExistGlsl == YES || isExistMetal == YES)) {
            return NO;
        }
        else
        {
            return YES;
        }
    }
}

- (void)cacheCompiledShader:(NSString *)filePath
{
    NSString *cacheKey = [filePath lastPathComponent];
    NSString *fileMD5 = [SFileMD5Generator generateMD5ForFileAtPath:filePath];
    self.md5Dic[cacheKey] = fileMD5;
}

- (void)saveshaderFileMD5Cache
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:self.md5Dic forKey:@"compiledShaderInfoKey"];
    [userDefaults synchronize];
}

#pragma mark Getter
- (NSMutableDictionary *)md5Dic
{
    if (_md5Dic == nil)
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        _md5Dic = [[NSMutableDictionary alloc] initWithDictionary:[userDefaults valueForKey:@"compiledShaderInfoKey"]];
        if (_md5Dic == nil)
        {
            _md5Dic = [[NSMutableDictionary alloc] init];
        }
    }
    return _md5Dic;
}

@end
