//
//  SBgfxConverterParameters.m
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import "SBgfxConverterParameters.h"

@implementation SBgfxConverterParameters

- (instancetype)init {
    self = [super init];
    if (self) {
        _optimizeLevel = @"3";
        _shaderModel = @"";
    }
    return self;
}

- (NSArray<NSString *> *)setupCompileParamArray
{
    return @[@"-f", self.inputFilePath,
            @"-o", self.outputFilePath,
            @"-i", self.bgfxSrcPath,
            @"--varyingdef", self.defFilePath,
            @"--platform", self.platform,
            @"-p", self.shaderModel,
            @"--type",self.shaderType,
            @"-O",self.optimizeLevel];
}

@end
