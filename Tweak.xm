  // 1. 百度贴吧主包常见的开屏/广告类覆盖列表
  NSArray *targetClasses = @[
      @"TBSplashViewController",
      @"TBAdSplashViewController",
      @"TBLaunchAdViewController",
      @"TBAdvertSplashViewController",
      @"TBBaseAdViewController",
      @"TBCSplashView",
      @"TBAdSplashView",
      @"TBCAdManager",
      @"TBAdService"
  ];

  for (NSString *className in targetClasses) {
      Class cls = NSClassFromString(className);
      if (cls) {
          NSLog(@"[TiebaAdFree] Found target class: %@", className);
          
          Method method = class_getInstanceMethod(cls, @selector(viewDidLoad));
          if (method) {
              IMP originalImp = method_getImplementation(method);
              void (*originalTyped)(id, SEL) = (void (*)(id, SEL))originalImp;
              
              IMP newImp = imp_implementationWithBlock(^void(id self) {
                  originalTyped(self, @selector(viewDidLoad));
                  NSLog(@"[TiebaAdFree] %@ viewDidLoad called. Dismissing...", className);
                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                      UIViewController *vc = (UIViewController *)self;
                      if ([vc isKindOfClass:[UIViewController class]]) {
                          [vc.view removeFromSuperview];
                          if ([vc respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
                              [vc dismissViewControllerAnimated:NO completion:nil];
                          }
                      }
                  });
              });
              method_setImplementation(method, newImp);
          }
      }
  }

  // 2. 全局劫持 UIWindow，自动扫描并移除所有开屏广告视图
  Class windowClass = NSClassFromString(@"UIWindow");
  if (windowClass) {
      Method makeKeyMethod = class_getInstanceMethod(windowClass, @selector(makeKeyAndVisible));
      if (makeKeyMethod) {
          IMP originalImp = method_getImplementation(makeKeyMethod);
          void (*originalTyped)(id, SEL) = (void (*)(id, SEL))originalImp;
          
          IMP newImp = imp_implementationWithBlock(^void(id self) {
              originalTyped(self, @selector(makeKeyAndVisible));
              UIWindow *window = (UIWindow *)self;
              for (UIView *subview in window.subviews) {
                  NSString *className = NSStringFromClass([subview class]);
                  if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || [className containsString:@"Advert"]) {
                      NSLog(@"[TiebaAdFree] Found ad window subview: %@. Removing...", className);
                      subview.hidden = YES;
                      [subview removeFromSuperview];
                  }
              }
          });
          method_setImplementation(makeKeyMethod, newImp);
      }
  }
