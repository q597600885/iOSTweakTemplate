#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

%hook SKPaymentQueue

// 拦截添加支付请求，直接模拟成功或直接返回
- (void)addPayment:(SKPayment *)payment {
    NSLog(@"[IAP_Bypass] Intercepted payment for product: %@", payment.productIdentifier);
    %orig; // 仍然走原本流程，或者在下面直接通过通知/代理模拟交易成功
}

%end

// 针对部分使用 StoreKit 凭证验证的 App
%hook SKReceiptRefreshRequest

- (void)start {
    // 阻止向苹果服务器发送刷新收据的请求，避免把伪造状态覆盖掉
    NSLog(@"[IAP_Bypass] SKReceiptRefreshRequest start blocked.");
}

%end