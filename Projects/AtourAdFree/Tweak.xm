#import <UIKit/UIKit.h>

%hook UIWindow

- (void)makeKeyAndVisible {
 %orig;
 dispatch_async(dispatch_get_main_queue(), ^{
 UIWindow *window = (UIWindow *)self;
 for (UIView *subview in window.subviews) {
 NSString *className = NSStringFromClass([subview class]);
 if ([className containsString:@"Launch"] ||
 [className containsString:@"Splash"] ||
 [className containsString:@"Ad"]) {
 subview.hidden = YES;
 [subview removeFromSuperview];
 }
 }
 });
}

%end
