//
//  SFolderConfigs.h
//  shader-converter
//
//  Created by 王江 on 2020/10/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// root folder's name to save shaders
extern NSString *const kShaderRootFolderName;

extern NSString *const kBgfxDependencyFolderSubpath;

extern NSString *const kVertexShaderFolderSubpath;

extern NSString *const kFragmentShaderFolderSubpath;

@interface SFolderConfigs : NSObject

@property (nonatomic, copy, readonly) NSString *rootPath;

@property (nonatomic, copy, readonly) NSString *bgfxDependencyPath;

/// config the root of shaders
/// @param root the root path
- (instancetype)initWithShaderRootPath:(NSString *)root;

@end

NS_ASSUME_NONNULL_END
