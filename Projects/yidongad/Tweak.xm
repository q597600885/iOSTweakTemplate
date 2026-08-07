#import <UIKit/UIKit.h>

// ============================================================================
// 1. 递归工具函数：扫描 View 及其子视图中是否包含“跳过”文字
// ============================================================================
static BOOL hasSkipTextInView(UIView *view) {
    if (!view) return NO;

    // 检查 UILabel 的文本
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if (label.text && [label.text containsString:@"跳过"]) {
            return YES;
        }
    }
    // 检查 UIButton 的标题
    else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        if (button.currentTitle && [button.currentTitle containsString:@"跳过"]) {
            return YES;
        }
    }

    // 递归遍历所有子视图
    for (UIView *subview in view.subviews) {
        if (hasSkipTextInView(subview)) {
            return YES;
        }
    }
    return NO;
}


// ============================================================================
// 2. Hook UIView：全局扫描包含“跳过”按钮的开屏 View 并彻底移除
// ============================================================================

%hook UIView

- (void)didMoveToWindow {
    %orig;

    if (self.window) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 只要发现当前 View 包含“跳过”字样
            if (hasSkipTextInView(self)) {
                NSString *clsName = NSStringFromClass([self class]);
                
                // 1. 立即隐藏并彻底移除开屏 View
                self.hidden = YES;
                [self removeFromSuperview];

                // 2. 在控制台打印，方便调试
                NSLog(@"[AdBlock] 成功捕获并移除中国移动开屏广告 View，真实类名为: %@", clsName);
            }
        });
    }
}

%end


// ============================================================================
// 3. 保证 100% 弹出注入成功提示（Hook 首个展示的 ViewController）
// ============================================================================

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hook 成功 🎉"
                                                                       message:@"中国移动插件已顺利注入！\n动态开屏拦截器已开启。"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];

        [self presentViewController:alert animated:YES completion:nil];
    });
}

%end
