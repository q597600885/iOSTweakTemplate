#import <UIKit/UIKit.h>

// 声明该 Class 继承自 UIView，让编译器识别 hidden 和 subviews 属性
@interface CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4 : UIView
@end

// 假设还有其他涉及到的类或 Delegate 声明
@protocol SplashAdDelegate <NSObject>
- (void)splashAd:(id)splashAd didFailWithError:(NSError *)error;
@end

@interface SplashAdLoader : NSObject
@property (nonatomic, weak) id<SplashAdDelegate> delegate;
@end


// ==========================================
// 1. 酷安/CoolMarket 列表广告 Cell 隐藏
// ==========================================
%hook CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4

- (id)initWithFrame:(CGRect)frame {
    id origSelf = %orig;
    if (origSelf) {
        // 强转为 UIView *，彻底规避类型找不到属性的问题
        UIView *view = (UIView *)origSelf;
        view.hidden = YES;
        
        // 遍历或清理子视图逻辑
        for (UIView *subview in view.subviews) {
            subview.hidden = YES;
        }
    }
    return origSelf;
}

- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    view.hidden = YES;
}

%end


// ==========================================
// 2. 开屏广告失败回调模拟
// ==========================================
%hook SplashAdLoader

- (void)loadAd {
    %orig;
    // 模拟广告加载失败，自动跳过开屏
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
        [self.delegate splashAd:self didFailWithError:nil];
    }
}

%end
