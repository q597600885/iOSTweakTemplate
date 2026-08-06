#import <UIKit/UIKit.h>

%hook LaunchImageVC

- (void)viewDidLoad {
    %orig;
    
    // 异步执行，确保视图已经加载准备好弹出提示
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        // 检查本地是否已经标记过
        BOOL hasShownAlert = [defaults boolForKey:@"AtourAdFree_HasShownSuccessAlert"];
        
        if (!hasShownAlert) {
            // 标记以后不再弹出
            [defaults setBool:YES forKey:@"AtourAdFree_HasShownSuccessAlert"];
            [defaults synchronize];
            
            // 弹出一次性成功提示框
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🎉 亚朵去广告插件" 
                                                                            message:@"插件已成功注入并首次生效！此提示仅出现一次。" 
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"太棒了" style:UIAlertActionStyleDefault handler:nil]];
            
            // 获取当前最顶层的 UIViewController 来弹窗
            UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

%end
