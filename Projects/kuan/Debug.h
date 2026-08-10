#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ----------------------------------------------------------------------------
// 1. 安全高效日志输出 (自动写入 App 沙盒 Documents/TweakDebug.log)
// ----------------------------------------------------------------------------
static void TweakLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    // 控制台输出 (可通过 Mac 控制台实时查看)
    NSLog(@"[TweakDebug] %@", msg);

    // 写入沙盒 Documents 目录 (100% 具备读写权限)
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"TweakDebug.log"];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeStr = [formatter stringFromDate:[NSDate date]];
    NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", timeStr, msg];

    // 文件句柄追加，性能开销极低
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fileHandle) {
        [logLine writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } else {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    }
}

// ----------------------------------------------------------------------------
// 2. 运行时类名扫描 (自动盲搜当前内存中的相关类)
// ----------------------------------------------------------------------------
static void ScanRuntimeClasses(NSString *keyword) {
    TweakLog(@"================ 开始扫描包含 [%@] 的 Runtime 类 ================", keyword);
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses <= 0) return;

    Class *classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);

    for (int i = 0; i < numClasses; i++) {
        NSString *className = NSStringFromClass(classes[i]);
        if ([className localizedCaseInsensitiveContainsString:keyword]) {
            TweakLog(@"[Find Class] %@", className);
        }
    }
    free(classes);
    TweakLog(@"================ 扫描完成 ================");
}
