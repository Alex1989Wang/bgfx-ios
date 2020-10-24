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

typedef NS_ENUM(NSInteger, emShaderCompileType) {
    emShaderCompileTypeVertex = 1,
    emShaderCompileTypeFragment
};

@interface SShaderConverter()

@property(nonatomic, strong) SBgfxConverterWrapper *mShaderCompiler;

@property(nonatomic, strong) SShaderFileLookup *mFileManager;

@property(nonatomic, strong) NSMutableDictionary *md5Dic;

@property(nonatomic, strong) NSArray<NSString *> *compilePlatform;

@property(nonatomic, strong) NSString *mBGFXSrcPath;

@end

@implementation SShaderConverter

- (instancetype)init
{
    NSAssert(NO, @"请使用initWithMainShaderFilePath:");
    return [self initWithMainShaderFilePath:@"" andBGFXSrcPath:@""];
}

- (instancetype)initWithMainShaderFilePath:(NSString *)mainShaderFilePath
                            andBGFXSrcPath:(nonnull NSString *)srcPath
{
    self = [super init];
    if (self)
    {
        _mFileManager = [[SShaderFileLookup alloc] initWithMainShaderFilePath:mainShaderFilePath];
        _mShaderCompiler = [[SBgfxConverterWrapper alloc] init];
//        _compilePlatform = @[@"metal,ios,metal,metal",
//                             @"glsl,linux,120,120"];
        _mBGFXSrcPath = srcPath;
    }
    return self;
}


- (void)setCompilePlatform:(NSArray<NSString *> *)platform
{
    _compilePlatform = platform;
}

- (void)startCompile:(BOOL)needLog
{
    [self preCompile:needLog];
    [self compile:needLog];
}

- (void)preCompile:(BOOL)needLog
{
    //把公用的vs强行转换一次
    NSLog(@"🍏先转换公用的vs");
    NSString *commonVSFilePath = [self.mFileManager mDefaultVertexFilePath];
    NSString *commonDefFilePath = [self.mFileManager mDefaultDefineFilePath];
    [self.compilePlatform enumerateObjectsUsingBlock:^(NSString *platformInfo, NSUInteger idx, BOOL *stop) {
        NSString *compileOutputPath = [self compileShader:@"bgfx/common/common.fs"
                                           shaderFilePath:commonVSFilePath
                                              defFilePath:commonDefFilePath
                                              compileType:emShaderCompileTypeVertex
                                                 platform:platformInfo
                                             shaderSuffix:@"vs"
                                               andNeedLog:needLog];
        if (self.isRelease && compileOutputPath != nil)
        {
        }
    }];
    
    NSLog(@"=======================================================");
}

- (void)compile:(BOOL)needLog
{
    NSLog(@"🍎再开始转换其他shader");
    
    /** 获取目录下的所有片元着色器进行遍历 **/
    NSArray<NSString *> *allFragmentsFileArr = [self.mFileManager getAllFragmentFile];

    //每次转换的结果
    __block BOOL compileResult = YES;
    //统计总共转换的次数
    __block NSInteger compileFSCount = 0;
    __block NSInteger compileVSCount = 0;
    __block NSInteger noNeedCompileCount = 0;
    __block NSInteger useDefaultShaderVCCount = 0;
    NSMutableArray<NSString *> *failedShaderArr = [[NSMutableArray alloc] init];
    [allFragmentsFileArr enumerateObjectsUsingBlock:^(NSString *fragmentPath, NSUInteger index, BOOL *stop) {
        /** 判断是否需要重要编译，以及需要编译哪些shader **/
        emShaderCompileOption compileType = [self decideShaderCompileType:fragmentPath];
        if (compileType != emShaderCompileOptionNone)
        {
            BOOL isDefaultDefFile = NO;
            BOOL isDefaultVertextFile = NO;
            /** 获取片元着色器文件绝对路径 **/
            NSString *fragmentFilePath = [self.mFileManager getFragmentFileWithFragmentFile:fragmentPath];
            
            /** 获取define文件的绝对路径 **/
            NSString *defFilePath = [self.mFileManager getDefineFileWithFragmentFile:fragmentPath
                                                                 isDefaultDefineFile:&isDefaultDefFile];
            /** 获取顶点着色器文件绝对路径 **/
            NSString *vertexFilePath = [self.mFileManager getVertexFileWithFragmentFile:fragmentPath
                                                                    isDefaultVertexFile:&isDefaultVertextFile];
            /** 获取顶点着色器文件的相对路径(相对于bgfx始) **/
            NSString *vertexPath = [vertexFilePath substringFromIndex:[vertexFilePath rangeOfString:@"bgfx"].location];
            
            if (isDefaultVertextFile || isDefaultDefFile)
            {
                NSAssert((isDefaultVertextFile && isDefaultDefFile), @"vs和def应该配套出现，要么都用公用的，要么都是自己特定的");
            }
           
            //判断是否需要编译片元着色器
            if (compileType & emShaderCompileTypeFragment)
            {
                [self.compilePlatform enumerateObjectsUsingBlock:^(NSString *platformInfo, NSUInteger idx, BOOL *stop) {
                    /** 编译片元着色器 **/
                    compileFSCount++;
                    NSString *compileOutputPath = [self compileShader:fragmentPath
                                                       shaderFilePath:fragmentFilePath
                                                          defFilePath:defFilePath
                                                          compileType:emShaderCompileTypeFragment
                                                             platform:platformInfo
                                                         shaderSuffix:@"fs"
                                                           andNeedLog:needLog];
                    compileResult = compileOutputPath != nil;
                    if (compileResult)
                    {
                        if (self.isRelease)
                        {
                        }
                    }
                    else
                    {
                        NSAssert(NO, @"%@-%@转换失败", fragmentPath, platformInfo);
                        [failedShaderArr addObject:[NSString stringWithFormat:@"%@-%@", fragmentPath, platformInfo]];
                    }
                }];
                if (compileResult)
                {
                    //既然编译成功了，那么就需要做MD5缓存，方便下次判断是否需要重新编译。
                    //为了简化流程，不去判断到底该缓存什么，这里简单粗暴地处理：只要不是公用的存def和vertex，不论是否有变化，都直接缓存。
                    /** 获取define文件的相对路径(相对于bgfx始) **/
                    if (!isDefaultDefFile)
                    {
                        NSString *defPath = [defFilePath substringFromIndex:[defFilePath rangeOfString:@"bgfx"].location];
                        [self cacheCompiledShader:defFilePath cacheKey:defPath];
                    }
                    [self cacheCompiledShader:fragmentFilePath cacheKey:fragmentPath];

                }
            }
            //判断是否需要编译顶点着色器
            if ((!isDefaultVertextFile) && (compileType & emShaderCompileTypeVertex))
            {
                [self.compilePlatform enumerateObjectsUsingBlock:^(NSString *platformInfo, NSUInteger idx, BOOL *stop) {
                    /** 编译顶点着色器 **/
                    compileVSCount++;
                    NSString *compileOutputPath = [self compileShader:fragmentPath
                                                       shaderFilePath:vertexFilePath
                                                          defFilePath:defFilePath
                                                          compileType:emShaderCompileTypeVertex
                                                             platform:platformInfo
                                                         shaderSuffix:@"vs"
                                                           andNeedLog:needLog];
                    
                    compileResult = compileOutputPath != nil;
                    if (compileResult)
                    {
                        if (self.isRelease)
                        {
                        }
                    }
                    else
                    {
                        NSAssert(NO, @"%@-%@转换失败", vertexPath, platformInfo);
                        [failedShaderArr addObject:[NSString stringWithFormat:@"%@-%@", vertexPath, platformInfo]];
                    }
                }];
                if (compileResult)
                {
                    //既然编译成功了，那么就需要做MD5缓存，方便下次判断是否需要重新编译。
                    //为了简化流程，不去判断到底该缓存什么，这里简单粗暴地处理：只要不是公用的存def和vertex，不论是否有变化，都直接缓存。
                    /** 获取define文件的相对路径(相对于bgfx始) **/
                    if (!isDefaultDefFile)
                    {
                        NSString *defPath = [defFilePath substringFromIndex:[defFilePath rangeOfString:@"bgfx"].location];
                        [self cacheCompiledShader:defFilePath cacheKey:defPath];
                    }
                    [self cacheCompiledShader:vertexFilePath cacheKey:vertexPath];
                }
            }
        }
        else
        {
            NSLog(@"文件%@的MD5有对应cache的并且与cache的MD5相同，表示文件没有变化，不进行转换",fragmentPath);
            NSLog(@"======================");
            noNeedCompileCount++;
        }
    }];
    
    //转换结束，更新公用的def和vertext文件的MD5
    /** 获取公用define文件的绝对路径 **/
    NSString *commenDefFilePath = [self.mFileManager mDefaultDefineFilePath];
    /** 获取公用define文件的相对路径(相对于bgfx始) **/
    NSString *commonDefPath = [commenDefFilePath substringFromIndex:[commenDefFilePath rangeOfString:@"bgfx"].location];
    
    /** 获取公用顶点着色器文件绝对路径 **/
    NSString *commonVertexFilePath = [self.mFileManager mDefaultVertexFilePath];
    /** 获取公用顶点着色器文件的相对路径(相对于bgfx始) **/
    NSString *commonVertexPath = [commonVertexFilePath substringFromIndex:[commonVertexFilePath rangeOfString:@"bgfx"].location];
    
    [self cacheCompiledShader:commenDefFilePath cacheKey:commonDefPath];
    [self cacheCompiledShader:commonVertexFilePath cacheKey:commonVertexPath];
    
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
    NSString *outputDir = [self.mFileManager setupCompileOutputDirectory:shaderFileRelativePath
                                                             andPlatform:platform
                                                           withIsRelease:self.isRelease];
    NSString *shaderFileName = [shaderName stringByAppendingPathExtension:suffix];
    if (self.isRelease)
    {
        shaderFileName = [SFileMD5Generator MD5ForString:shaderFileName withIsRelease:YES];
    }
    NSString *shaderOutputPath = [self.mFileManager setupCompileOutputPath:outputDir
                                                         andShaderFileName:shaderFileName];
    return shaderOutputPath;
}

- (NSString *)compileShader:(NSString *)shaderRelativePath
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
    
    [compileParam setBgfxSrcPath:self.mBGFXSrcPath];
    
    NSArray<NSString *> *platformInfo = [platform componentsSeparatedByString:@","];
    [compileParam setPlatform:platformInfo[1]];
    NSString *shaderModel = shaderType == emShaderCompileTypeVertex ? platformInfo[2] : platformInfo[3];
    [compileParam setShaderModel:shaderModel ? shaderModel : @""];

    self.mShaderCompiler.bgfxShaderCToolPath = self.bgfxShaderCToolPath;
    return [self.mShaderCompiler compileShaderWithParam:compileParam needLog:needToLog];
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
    NSString *fileMD5 = [SFileMD5Generator generateMD5:filePath];
    
    NSString *cacheKey = [filePath substringFromIndex:[filePath rangeOfString:@"bgfx"].location];
    NSString *cachedFileMD5 = self.md5Dic[cacheKey];
    
    BOOL fileChanged = ![cachedFileMD5 isEqualToString:fileMD5];
    
    if(isDefault)
    {
        return fileChanged;
    }
    else
    {
        //还需要判断是否存在现在编译环境需要的路径
        NSString *bundleStr = [NSString stringWithFormat:@"%@.bundle", [SFileMD5Generator MD5ForString:@"output" withIsRelease:_isRelease]];
        NSString *lastPath = [cacheKey stringByReplacingOccurrencesOfString:@"bgfx/" withString:@""];
        NSMutableArray<NSString *> *lastPathComposition = [[lastPath pathComponents] mutableCopy];
        __weak typeof(self) weakSelf = self;
        [lastPathComposition enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //获取路径最后部分加密后的字符串组合
            lastPathComposition[idx] = [SFileMD5Generator MD5ForString:obj withIsRelease: weakSelf.isRelease];
        }];
        NSString *encodeLastPath = [NSString pathWithComponents:lastPathComposition];
        
        NSString *encodePlatformMetalStr = [SFileMD5Generator MD5ForString:@"metal" withIsRelease: _isRelease];
        NSString *currentMetalPath = [NSString stringWithFormat:@"%@/%@/%@/%@",_mFileManager.mainShaderFilePath,bundleStr,encodePlatformMetalStr,encodeLastPath];
        BOOL isExistMetal = [[NSFileManager defaultManager] fileExistsAtPath:currentMetalPath];
        
        NSString *encodePlatformGlslStr = [SFileMD5Generator MD5ForString:@"glsl" withIsRelease: _isRelease];
        NSString *currentGlslPath = [NSString stringWithFormat:@"%@/%@/%@/%@",_mFileManager.mainShaderFilePath,bundleStr,encodePlatformGlslStr,encodeLastPath];
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

- (void)cacheCompiledShader:(NSString *)filePath cacheKey:(NSString *)cacheKey
{
    NSString *fileMD5 = [SFileMD5Generator generateMD5:filePath];
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
