//
//  SFileMD5Generator.h
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SFileMD5Generator : NSObject

/**
 *
 *  @date           2018-10-24
 *  @author         Wall-E
 *  @description    获取一个文件的MD5，以判断文件是否被修改过
 *
 *  @param          filePath           文件路径
 *
 *  @return         NSString *         文件的MD5
 *
 **/
+ (NSString *)generateMD5:(NSString *)filePath;

/**
 对文件夹名字进行MD5

 @param string 输入字符串
 @param isRelease 是否是releasej环境，release就加密
 @return 输出字符串
 */
+ (NSString *)MD5ForString:(NSString *)string withIsRelease:(BOOL) isRelease;
@end

NS_ASSUME_NONNULL_END
