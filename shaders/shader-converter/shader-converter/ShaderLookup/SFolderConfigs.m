//
//  SFolderConfigs.m
//  shader-converter
//
//  Created by 王江 on 2020/10/24.
//

#import "SFolderConfigs.h"

NSString *const kShaderRootFolderName = @"shaders";

NSString *const kBgfxDependencyFolderSubpath = @"/common/src";

NSString *const kVertexShaderFolderSubpath = @"/vertexs";

NSString *const kFragmentShaderFolderSubpath = @"/fragments";

@implementation SFolderConfigs

- (instancetype)initWithShaderRootPath:(NSString *)root {
    self = [super init];
    if (self) {
        _rootPath = root;
    }
    return self;
}

- (NSString *)bgfxDependencyPath {
    return [NSString stringWithFormat:@"%@%@", self.rootPath, kBgfxDependencyFolderSubpath];
}

@end
