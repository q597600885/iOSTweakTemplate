#import <UIKit/UIKit.h>
#import "../../Includes/Debug.h" 

#define LOG_TAG @"ruixingcoffee"

%ctor {
    ResetDebugLog(LOG_TAG);
    
    ScanRuntimeClasses(LOG_TAG, @"AdManager");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(LOG_TAG, @"🎉 插件 ruixingcoffee 已成功启动！");
    }];
}
