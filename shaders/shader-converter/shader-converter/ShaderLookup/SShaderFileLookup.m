//
//  SShaderFileLookup.m
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import "SShaderFileLookup.h"
#import "SFileMD5Generator.h"

NSString *const kShaderRootFolderName = @"shaders";

NSString *const kBgfxDependencyFolderSubpath = @"/common/src";

NSString *const kVertexShaderPathExtension = @"vs";

NSString *const kFragmentShaderPathExtension = @"fs";

NSString *const kShaderOutputFolderName = @"output";

@interface SShaderFileLookup()

@property(nonatomic, copy) NSString *rootPath;

@property(nonatomic, strong) NSFileManager *mFileMgr;

@end

@implementation SShaderFileLookup

- (instancetype)initWithShaderFolderPath:(NSString *)shaderRootPath {
    self = [super init];
    if (self) {
        _rootPath = shaderRootPath;
        _mFileMgr = [NSFileManager defaultManager];
        _mDefaultDefineFilePath = [self.bgfxDependencyPath stringByAppendingPathComponent:@"/varying.def.sc"];
        _mDefaultVertexFilePath = [self.rootPath stringByAppendingPathComponent:@"/common/common.vs"];
    }
    return self;
}

- (NSDictionary<NSNumber *,NSArray<NSString *> *> *)getAllShaderFilesSubpaths {
    NSMutableDictionary<NSNumber *, NSMutableArray<NSString *> *> *map = [NSMutableDictionary dictionary];
    NSDirectoryEnumerator<NSString *> *dirEnumerator = [self.mFileMgr enumeratorAtPath:self.rootPath];
    // enumerating
    NSString *subpath = dirEnumerator.nextObject;
    while (subpath.length) {
        // if it's an compiled file
        if ([subpath containsString:kShaderOutputFolderName]) {
            subpath = dirEnumerator.nextObject;
            continue;
        }
        NSString *pathExt = [subpath pathExtension];
        // vertex shader
        if ([pathExt isEqualTo:kVertexShaderPathExtension]) {
            NSMutableArray<NSString *> *paths = map[@(emShaderCompileTypeVertex)];
            if (!paths) {
                paths = [NSMutableArray array];
                map[@(emShaderCompileTypeVertex)] = paths;
            }
            [paths addObject:subpath];
        }
        // fragment shader
        else if ([pathExt isEqualTo:kFragmentShaderPathExtension]) {
            NSMutableArray<NSString *> *paths = map[@(emShaderCompileTypeFragment)];
            if (!paths) {
                paths = [NSMutableArray array];
                map[@(emShaderCompileTypeFragment)] = paths;
            }
            [paths addObject:subpath];
        }
        // next
        subpath = dirEnumerator.nextObject;
    }
    return [map copy];
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

- (NSString *)getFragmentFileWithFragmentFile:(NSString *)fragmentFilePath {
    return [self setupWholeFilePathWithRelativePath:fragmentFilePath];
}

- (NSString *)getShaderFileName:(NSString *)shaderFilePath
{
    return [[shaderFilePath stringByDeletingPathExtension] lastPathComponent];
}

- (NSString *)setupShaderOutputDirectory:(NSString *)fragmentFilePath withPlatform:(NSString *)platform isRelease:(BOOL) isRelease
{
    NSMutableArray<NSString *> *pathComposition = [[fragmentFilePath pathComponents] mutableCopy];
    pathComposition[0] = platform;
    NSString *bundleStr = [NSString stringWithFormat:@"%@.bundle", kShaderOutputFolderName];
    [pathComposition insertObject:bundleStr atIndex:0];
    
    NSString *platformDir = [[NSString pathWithComponents:pathComposition] stringByDeletingLastPathComponent];
    NSString *wholePlatformDir = [self setupWholeFilePathWithRelativePath:platformDir];
    if (![self.mFileMgr fileExistsAtPath:wholePlatformDir]) {
        [self.mFileMgr createDirectoryAtPath:wholePlatformDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return wholePlatformDir;
}

- (NSString *)setupCompileOutputPath:(NSString *)outputDir andShaderFileName:(NSString *)fileName
{
    return [outputDir stringByAppendingPathComponent:fileName];
}

#pragma mark - 內部方法
- (NSString *)setupWholeFilePathWithRelativePath:(NSString *)relativePath {
    return [self.rootPath stringByAppendingPathComponent:relativePath];
}

#pragma mark Getter
- (NSString *)bgfxDependencyPath {
    return [NSString stringWithFormat:@"%@%@", self.rootPath, kBgfxDependencyFolderSubpath];
}

@end
