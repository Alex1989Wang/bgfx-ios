//
//  SBgfxConverterWrapper.m
//  shader-converter
//
//  Created by 王江 on 2020/10/25.
//

#import "SBgfxConverterWrapper.h"

#import "SBgfxConverterParameters.h"

@implementation SBgfxConverterWrapper

- (BOOL)compileShaderWithParam:(SBgfxConverterParameters *)compileParam needLog:(BOOL)needLog
{
    NSArray<NSString *> *paramArr = [compileParam setupCompileParamArray];
    NSString *outputFilePath = [[compileParam.outputFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"txt"];
    return [self performCompileCommandWithParam:paramArr needLog:needLog andCompileOutputFilePath:outputFilePath];
}

#pragma mark - 内部方法
- (BOOL)performCompileCommandWithParam:(NSArray<NSString *> *)paramArray needLog:(BOOL)needLog andCompileOutputFilePath:(NSString *)outputFilePath
{
    NSURL *compilerURL = [NSURL fileURLWithPath:self.bgfxShaderCToolPath];

    NSTask *compileTask = [[NSTask alloc] init];

    [compileTask setExecutableURL:compilerURL];
    [compileTask setArguments:paramArray];

    NSPipe *outputPipe = [NSPipe pipe];
    if (needLog)
    {
        [compileTask setStandardOutput:outputPipe];
        [compileTask setStandardError:outputPipe];
    }

    __block BOOL bRet = false;
    [compileTask setTerminationHandler:^(NSTask *task) {
        int status = [task terminationStatus];
        NSTaskTerminationReason reason = [task terminationReason];

        bRet = ((status == 0) && (reason == NSTaskTerminationReasonExit));
    }];
    

    NSError *error = nil;
    [compileTask launchAndReturnError:&error];
    [compileTask waitUntilExit];

    if (!bRet)
    {
        if (needLog)
        {
            NSFileHandle * read = [outputPipe fileHandleForReading];
            NSData * outputData= [read readDataToEndOfFile];
            [outputData writeToFile:outputFilePath atomically:YES];
            
            NSLog(@"🔥转换出错，相关的输出日志为：%@\n", [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding]);
        }
    }
    else
    {
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    }

    return bRet;
}

@end
