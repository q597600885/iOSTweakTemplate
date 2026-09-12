#import <UIKit/UIKit.h>
#import "Includes/Debug.h" 

#define LOG_TAG @"WeifengAdBlock"

// ============================================================================
// 1. 极简基座测试 (不包含任何广告 Hook，仅测试编译环境与日志模块)
// ============================================================================

%ctor {
    // 初始化日志并清空旧数据
    ResetDebugLog(LOG_TAG);
    
    // 调用一次扫描函数，防止编译器报 unused-function 错误
    ScanRuntimeClasses(LOG_TAG, @"Splash");
    
    // 注册启动监听
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(LOG_TAG, @"🎉 极简基座测试成功！编译环境和头文件引用完全没问题！");
    }];
}
