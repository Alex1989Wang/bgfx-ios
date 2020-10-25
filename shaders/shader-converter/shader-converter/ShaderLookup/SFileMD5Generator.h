//
//  SFileMD5Generator.h
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SFileMD5Generator : NSObject

/// md5 digest for a file
+ (NSString *)generateMD5ForFileAtPath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
