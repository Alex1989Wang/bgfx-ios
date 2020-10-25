//
//  SShaderFileLookup.h
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, emShaderCompileType) {
    emShaderCompileTypeVertex = 1,
    emShaderCompileTypeFragment
};

// root folder's name to save shaders
extern NSString *const kShaderRootFolderName;

extern NSString *const kBgfxDependencyFolderSubpath;

extern NSString *const kVertexShaderPathExtension;

extern NSString *const kFragmentShaderPathExtension;

extern NSString *const kShaderOutputFolderName;

/// manage shader files and directories
@interface SShaderFileLookup : NSObject

@property (nonatomic, copy, readonly) NSString *rootPath; //the root folder for all shader files

@property (nonatomic, copy, readonly) NSString *bgfxDependencyPath;

@property(nonatomic, strong, readonly) NSString *mDefaultVertexFilePath;

@property(nonatomic, strong, readonly) NSString *mDefaultDefineFilePath;

- (instancetype)init NS_UNAVAILABLE;

/// config the root of shaders
/// @param shaderRootPath the root path
- (instancetype)initWithShaderFolderPath:(NSString *)shaderRootPath NS_DESIGNATED_INITIALIZER;

/// relative paths for all shader files
/// shader type to file subpaths map
- (NSDictionary<NSNumber *, NSArray<NSString *> *> *)getAllShaderFilesSubpaths;

/// absolute path for a vertex shader path
- (NSString *)getVertexFileWithFragmentFile:(NSString *)fragmentFilePath isDefaultVertexFile:(BOOL *)isDefaultFile;

/// absolute path for a define (.sh) file
- (NSString *)getDefineFileWithFragmentFile:(NSString *)fragmentFilePath isDefaultDefineFile:(BOOL *)isDefaultFile;

- (NSString *)getFragmentFileWithFragmentFile:(NSString *)fragmentFilePath;

/// extracting the shader file name from its file path
- (NSString *)getShaderFileName:(NSString *)shaderFilePath;

/// setup the converted shaders file directory
- (NSString *)setupShaderOutputDirectory:(NSString *)filePath withPlatform:(NSString *)platform isRelease:(BOOL) isRelease;

/// the converted shader's output file path
- (NSString *)setupCompileOutputPath:(NSString *)outputDir andShaderFileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
