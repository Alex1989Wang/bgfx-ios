//
//  SShaderFileLookup.m
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import "SShaderFileLookup.h"
#import "SFileMD5Generator.h"

@interface SShaderFileLookup()

@property(nonatomic, strong) NSString *mMainPath;

@property(nonatomic, strong) NSFileManager *mFileMgr;

//@property(nonatomic, strong, readwrite) NSString *mDefaultVertexFilePath;
//
//@property(nonatomic, strong, readwrite) NSString *mDefaultDefineFilePath;

@end

@implementation SShaderFileLookup

- (instancetype)init
{
    NSAssert(NO, @"请使用initWithMainShaderFilePath:");
    return [self initWithMainShaderFilePath:@""];
}

- (instancetype)initWithMainShaderFilePath:(NSString *)mainShaderFilePath
{
    self = [super init];
    if (self)
    {
        _mFileMgr = [NSFileManager defaultManager];
        _mMainPath = mainShaderFilePath;
        _mDefaultDefineFilePath = [mainShaderFilePath stringByAppendingPathComponent:@"bgfx/default/common.def"];
        _mDefaultVertexFilePath = [mainShaderFilePath stringByAppendingPathComponent:@"bgfx/default/common.vs"];
    }
    return self;
}

- (NSArray<NSString *> *)getAllFragmentFile
{
    NSString *bgfxPath = [self.mMainPath stringByAppendingPathComponent:@"bgfx"];

    NSDirectoryEnumerator *directoryEnumerator = [self.mFileMgr enumeratorAtPath:bgfxPath];

    NSString *filePath = nil;
    NSMutableArray<NSString *> *allFragmentFiles = [[NSMutableArray alloc] init];
    while (filePath = [directoryEnumerator nextObject])
    {
        if ([[filePath pathExtension] isEqualToString:@"fs"])
        {
            NSString *relativeFilePath = [@"bgfx" stringByAppendingPathComponent:filePath];
            [allFragmentFiles addObject:relativeFilePath];
        }
    }
    return allFragmentFiles;
}

- (NSString *)getVertexFileWithFragmentFile:(NSString *)fragmentFilePath isDefaultVertexFile:(BOOL *)isDefaultFile
{
    NSString *vertexFilePath = [[fragmentFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"vs"];
    NSString *wholeVertexFilePath = [self setupWholeFilePathWithRelativePath:vertexFilePath];
    if ([self.mFileMgr fileExistsAtPath:wholeVertexFilePath])
    {
        *isDefaultFile = NO;
    }
    else
    {
        wholeVertexFilePath = self.mDefaultVertexFilePath;
        *isDefaultFile = YES;
    }
    return wholeVertexFilePath;
}

- (NSString *)getDefineFileWithFragmentFile:(NSString *)fragmentFilePath isDefaultDefineFile:(BOOL *)isDefaultFile
{
    NSString *defineFilePath = [[fragmentFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"def"];
    NSString *wholeDefineFilePath = [self setupWholeFilePathWithRelativePath:defineFilePath];
    if ([self.mFileMgr fileExistsAtPath:wholeDefineFilePath])
    {
        *isDefaultFile = NO;
    }
    else
    {
        wholeDefineFilePath= self.mDefaultDefineFilePath;
        *isDefaultFile = YES;
    }
    return wholeDefineFilePath;
}

- (NSString *)getFragmentFileWithFragmentFile:(NSString *)fragmentFilePath
{
    return [self setupWholeFilePathWithRelativePath:fragmentFilePath];
}

- (NSString *)getDefaultVertexShaderPath:(NSString *)platform
{
    NSMutableArray<NSString *> *pathComposition = [[@"bgfx/default/common.vs" pathComponents] mutableCopy];
    pathComposition[0] = platform;
    
    [pathComposition insertObject:@"output.bundle" atIndex:0];
    
    NSString *platformDir = [NSString pathWithComponents:pathComposition];
    NSString *wholePlatformDir = [self setupWholeFilePathWithRelativePath:platformDir];
    return wholePlatformDir;
}

- (NSString *)getShaderFileName:(NSString *)shaderFilePath
{
    return [[shaderFilePath stringByDeletingPathExtension] lastPathComponent];
}

- (NSString *)setupCompileOutputDirectory:(NSString *)fragmentFilePath andPlatform:(NSString *)platform withIsRelease:(BOOL) isRelease
{
    NSMutableArray<NSString *> *pathComposition = [[fragmentFilePath pathComponents] mutableCopy];
    pathComposition[0] = platform;
    [pathComposition enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        pathComposition[idx] = [SFileMD5Generator MD5ForString:obj withIsRelease: isRelease];
    }];
    
    NSString *bundleStr = [NSString stringWithFormat:@"%@.bundle", [SFileMD5Generator MD5ForString:@"output" withIsRelease:isRelease]];
    [pathComposition insertObject:bundleStr atIndex:0];
    
    NSString *platformDir = [[NSString pathWithComponents:pathComposition] stringByDeletingLastPathComponent];
    NSString *wholePlatformDir = [self setupWholeFilePathWithRelativePath:platformDir];
    if (![self.mFileMgr fileExistsAtPath:wholePlatformDir])
    {
        [self.mFileMgr createDirectoryAtPath:wholePlatformDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //文件存在，relese下要删除output.bundle,debug下要删除加密的文件
    NSString *needDeletebundleStr = [NSString stringWithFormat:@"%@.bundle", [SFileMD5Generator MD5ForString:@"output" withIsRelease:!isRelease]];
    NSString *needDeletePath = [self setupWholeFilePathWithRelativePath:needDeletebundleStr];
    if ([self.mFileMgr fileExistsAtPath:needDeletePath])
    {
       BOOL deleteRes = [self.mFileMgr removeItemAtPath:needDeletePath error:nil];
        NSLog(@"删除另一种j环境路径：%@ 结果：%d",needDeletePath, deleteRes);
    }
    return wholePlatformDir;
}

- (NSString *)setupCompileOutputPath:(NSString *)outputDir andShaderFileName:(NSString *)fileName
{
    return [outputDir stringByAppendingPathComponent:fileName];
}

#pragma mark - 內部方法
- (NSString *)setupWholeFilePathWithRelativePath:(NSString *)relativePath
{
    return [self.mMainPath stringByAppendingPathComponent:relativePath];
}

#pragma mark Getter
- (NSString *)mainShaderFilePath
{
    return self.mMainPath;
}

@end
