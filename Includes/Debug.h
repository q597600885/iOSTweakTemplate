#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ----------------------------------------------------------------------------
// 1. 获取日志写入路径 (存放在 App 沙盒 Documents 目录下，防权限报错)
// ----------------------------------------------------------------------------
static NSString* GetTweakLogPath(NSString *tag) {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fileName = [NSString stringWithFormat:@"%@_Debug.log", tag ? tag : @"Tweak"];
    return [docPath stringByAppendingPathComponent:fileName];
}

// ----------------------------------------------------------------------------
// 2. 自动刷新/清空日志 (App 每次冷启动自动擦除旧日志)
// ----------------------------------------------------------------------------
static void ResetDebugLog(NSString *tag) {
    NSString *path = GetTweakLogPath(tag);
    [@"" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// ----------------------------------------------------------------------------
// 3. 高效追加写入日志 (带时间戳)
// ----------------------------------------------------------------------------
static void TweakLog(NSString *tag, NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    // 控制台实时输出
    NSLog(@"[%@] %@", tag, msg);

    NSString *filePath = GetTweakLogPath(tag);

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeStr = [formatter stringFromDate:[NSDate date]];
    NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", timeStr, msg];

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
// 4. 通用 Runtime 内存类名盲搜
// ----------------------------------------------------------------------------
static void ScanRuntimeClasses(NSString *tag, NSString *keyword) {
    TweakLog(tag, @"================ 开始扫描包含 [%@] 的 Runtime 类 ================", keyword);
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses <= 0) return;

    Class *classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);

    for (int i = 0; i < numClasses; i++) {
        NSString *className = NSStringFromClass(classes[i]);
        if ([className localizedCaseInsensitiveContainsString:keyword]) {
            TweakLog(tag, @"[Find Class] %@", className);
        }
    }
    free(classes);
    TweakLog(tag, @"================ 扫描完成 ================");
}
