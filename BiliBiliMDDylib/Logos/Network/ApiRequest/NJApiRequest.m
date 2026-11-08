//
//  NJApiRequest.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2026/3/2.
//

#import "NJApiRequest.h"
#import "NJCommonDefine.h"
#import "BFCApiOptions.h"
#import "BFCApiRequest.h"
#import "BFCApiModelDescription.h"
#import "BFCAccount.h"
#import "BFCAccountHTTPCookie.h"
#import "NJMyPrivilegeModel.h"
#import "NJResponseModel.h"
#import "NJDailyTaskManager.h"

// 领取每日视频分享经验
#define NJ_RECEIVE_SHARE_EXPERIENCE_KEY @"NJ_RECEIVE_SHARE_EXPERIENCE_KEY"
// 领取每日经验
#define NJ_RECEIVE_DAILY_EXPERIENCE_KEY @"NJ_RECEIVE_DAILY_EXPERIENCE_KEY"
// 获取大会员卡券列表
#define NJ_LOAD_MY_PRIVILEGE_KEY @"NJ_LOAD_MY_PRIVILEGE_KEY"
// 大积分签到
#define NJ_BIG_POINT_SIGN_KEY @"NJ_BIG_POINT_SIGN_KEY"

/// 缓存的大积分数额（-1 表示未知）
static NSInteger NJBigPointCachedValue = -1;
/// 展示大积分的硬币 Label（弱引用）
static __weak UILabel *NJBigPointCoinLabel = nil;
/// 硬币 Label 原始文本
static NSString *NJBigPointCoinBaseText = nil;

/// 刷新硬币 Label（追加大积分数额）
static void NJRefreshBigPointCoinLabel(void) {
    UILabel *label = NJBigPointCoinLabel;
    if (!label) {
        return;
    }
    NSString *baseText = NJBigPointCoinBaseText ?: @"";
    if (NJBigPointCachedValue >= 0) {
        label.text = [NSString stringWithFormat:@"%@ · 大积分%ld", baseText, (long)NJBigPointCachedValue];
    } else {
        label.text = baseText;
    }
}

@implementation NJApiRequest

/// 执行启动任务
+ (void)runLaunchTasks {
    // 用户未登录
    if (![NSClassFromString(@"BFCAccount") nj_isLogin]) {
        return;
    }
    
    // 领取手动选择的大会员福利
    [self couponAutoReceiver];

    // 会员中心大积分自动签到（每天一次）
    if ([[NJDailyTaskManager shared] canRunTask:NJ_BIG_POINT_SIGN_KEY]) {
        [self signBigPointWithCompletionHandler:^(BOOL success, NSString *message) {
            if (success) {
                [[NJDailyTaskManager shared] markTaskDone:NJ_BIG_POINT_SIGN_KEY];
            }
        }];
    }
    
    // 领取每日视频分享经验
    if ([[NJDailyTaskManager shared] canRunTask:NJ_RECEIVE_SHARE_EXPERIENCE_KEY]) {
        [self receiveShareExperienceWithCompletionHandler:^(NSDictionary *dict) {
            NSLog(@"%@:%@-%p-%s-领取每日视频分享经验成功,dict:%@", nj_logPrefix, NSStringFromClass([(id)self class]), self, __FUNCTION__, dict);
            [[NJDailyTaskManager shared] markTaskDone:NJ_RECEIVE_SHARE_EXPERIENCE_KEY];
        } errorHandler:^(NSError *error, NSDictionary *dict) {
            NSLog(@"%@:%@-%p-%s-领取每日视频分享经验失败,error:%@-dict:%@", nj_logPrefix, NSStringFromClass([(id)self class]), self, __FUNCTION__, error, dict);
        }];
    }
}

/// 领取大会员福利（手动选择类型）
+ (void)couponAutoReceiver {
    // 领取类型：0=不领取
    NSInteger couponType = NJ_COUPON_TYPE_VALUE;
    // 不是大会员
    if (couponType != NJ_COUPON_TYPE_NONE &&
        [NSClassFromString(@"BFCAccount") nj_isVip]) {
        // 获取大会员卡券列表
        if ([[NJDailyTaskManager shared] canRunTask:NJ_LOAD_MY_PRIVILEGE_KEY]) {
            __weak typeof(self) weakSelf = self;
            [self loadMyPrivilegeWithCompletionHandler:^(NJMyPrivilegeModel *model) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                NSLog(@"%@:%@-%p-%s-获取大会员卡券列表成功，list count:%ld", nj_logPrefix, NSStringFromClass([(id)self class]), self, __FUNCTION__, [model list].count);
                [[NJDailyTaskManager shared] markTaskDone:NJ_LOAD_MY_PRIVILEGE_KEY];
                [strongSelf receiveCouponWithModel:model couponType:couponType];
            } errorHandler:^(NSError *error, NSDictionary *dict) {
                NSLog(@"%@:%@-%p-%s-获取大会员卡券列表失败，error:%@-dict:%@", nj_logPrefix, NSStringFromClass([(id)self class]), self, __FUNCTION__, error, dict);
            }];
        }
    }
    
    
    // 领取每日经验
    if ([[NJDailyTaskManager shared] canRunTask:NJ_RECEIVE_DAILY_EXPERIENCE_KEY]) {
        [self receiveDailyExperienceWithCompletionHandler:^(NSDictionary *dict) {
            NSLog(@"%@:%@-%p-%s-领取每日经验成功,dict:%@", nj_logPrefix, NSStringFromClass([(id)self class]), self, __FUNCTION__, dict);
            [[NJDailyTaskManager shared] markTaskDone:NJ_RECEIVE_DAILY_EXPERIENCE_KEY];
        } errorHandler:^(NSError *error, NSDictionary *dict) {
            NSLog(@"%@:%@-%p-%s-领取每日经验失败,error:%@-dict:%@", nj_logPrefix, NSStringFromClass([(id)self class]), self, __FUNCTION__, error, dict);
        }];
    }
}


/// 领取优惠券
/// - Parameters:
///   - model: 大会员福利 model
///   - couponType: 手动选择的领取类型
+ (void)receiveCouponWithModel:(NJMyPrivilegeModel *)model
                     couponType:(NSInteger)couponType {
    NSArray<NJCouponInfo *> *list = model.list;
    for (NJCouponInfo *info in list) {
        // 只领取用户手动选择的福利类型
        if (info.type == couponType && info.state == 0 && info.vip_type > 0) {
            [self receiveCouponWithType:info.type completionHandler:^(NSDictionary *dict) {
                NSLog(@"%@:%@-%p-%s-领取优惠券成功，type:%ld,dict:%@", nj_logPrefix, NSStringFromClass([(id)self class]), self, __FUNCTION__, info.type, dict);
            } errorHandler:^(NSError *error, NSDictionary *dict) {
                NSLog(@"%@:%@-%p-%s-领取优惠券失败，type:%ld,error:%@-dict:%@", nj_logPrefix, NSStringFromClass([(id)self class]), self, __FUNCTION__, info.type, error, dict);
            }];
        }
    }
}


/// 领取优惠券
/// - Parameter type: 优惠券类型
+ (void)receiveCouponWithType:(NSInteger)type
            completionHandler:(void (^)(NSDictionary *dict))completionHandler
                 errorHandler:(void (^)(NSError *error, NSDictionary *dict))errorHandler {
    NSString *cookieBiliJct = [NSClassFromString(@"BFCAccount") nj_getCookieBiliJct];
    BFCApiOptions *options = [NSClassFromString(@"BFCApiOptions") optionsWithBaseUrl:@"https://api.bilibili.com/x/vip/privilege/receive"];
    // POST
    options.requestMethod = 1;
    options.params = @{ @"type": [@(type) stringValue],
                        @"csrf": cookieBiliJct,};
    BFCApiModelDescription *response_Des = [NSClassFromString(@"BFCApiModelDescription") modelWith:@"/" mappingClass:NSClassFromString(@"NJResponseModel") isArray:NO isOptional:YES];
    options.modelDescriptions = @[response_Des];
    BFCApiRequest *request = [(BFCApiRequest *)[NSClassFromString(@"BFCApiRequest") alloc] initWithOptions:options];
    //     "Content-Type" = "application/json; charset=utf-8";
//    request.requestInjection = ^NSURLRequest *(NSURLRequest *request) {
//        NSMutableURLRequest *mutableRequest = [request mutableCopy];
//        [mutableRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
//        return mutableRequest;
//    };
    request.completionHandler = ^(NSDictionary *dict) {
        if (completionHandler) {
            completionHandler(dict);
        }
    };
    request.errorHandler = ^(NSError *error, NSDictionary *dict) {
        if (errorHandler) {
            errorHandler(error, dict);
        }
    };
    
    [request requestAsync];
}

/// 领取每日经验
+ (void)receiveDailyExperienceWithCompletionHandler:(void (^)(NSDictionary *dict))completionHandler
                                  errorHandler:(void (^)(NSError *error, NSDictionary *dict))errorHandler {
    NSString *cookieBiliJct = [NSClassFromString(@"BFCAccount") nj_getCookieBiliJct];
    BFCApiOptions *options = [NSClassFromString(@"BFCApiOptions") optionsWithBaseUrl:@"https://api.bilibili.com/x/vip/experience/add"];
    // POST
    options.requestMethod = 1;
    options.params = @{ @"csrf": cookieBiliJct,};
    BFCApiModelDescription *response_Des = [NSClassFromString(@"BFCApiModelDescription") modelWith:@"/" mappingClass:NSClassFromString(@"NJResponseModel") isArray:NO isOptional:YES];
    options.modelDescriptions = @[response_Des];
    BFCApiRequest *request = [(BFCApiRequest *)[NSClassFromString(@"BFCApiRequest") alloc] initWithOptions:options];
    request.completionHandler = ^(NSDictionary *dict) {
        if (completionHandler) {
            completionHandler(dict);
        }
    };
    request.errorHandler = ^(NSError *error, NSDictionary *dict) {
        if (errorHandler) {
            errorHandler(error, dict);
        }
    };
    
    [request requestAsync];
}
 
/// 获取大会员卡券列表
+ (void)loadMyPrivilegeWithCompletionHandler:(void (^)(NJMyPrivilegeModel *model))completionHandler errorHandler:(void (^)(NSError *error, NSDictionary *dict))errorHandler {
    // https://github.com/pskdje/bilibili-API-collect/blob/main/docs/vip/info.md
    BFCApiOptions *options = [NSClassFromString(@"BFCApiOptions") optionsWithBaseUrl:@"https://api.bilibili.com/x/vip/privilege/my"];
    options.params = @{};
    BFCApiModelDescription *coupon_Des = [NSClassFromString(@"BFCApiModelDescription") modelWith:@"/data" mappingClass:NSClassFromString(@"NJMyPrivilegeModel") isArray:NO isOptional:YES];
    options.modelDescriptions = @[coupon_Des];
    BFCApiRequest *request = [(BFCApiRequest *)[NSClassFromString(@"BFCApiRequest") alloc] initWithOptions:options];
    
    request.completionHandler = ^(NSDictionary *dict) {
        if (completionHandler) {
            completionHandler(dict[@"/data"]);
        }
    };
    request.errorHandler = ^(NSError *error, NSDictionary *dict) {
        if (errorHandler) {
            errorHandler(error, dict);
        }
    };
    
    [request requestAsync];
     
}

/// 领取每日视频分享经验
+ (void)receiveShareExperienceWithCompletionHandler:(void (^)(NSDictionary *dict))completionHandler
                                       errorHandler:(void (^)(NSError *error, NSDictionary *dict))errorHandler {
    NSString *oid = @"170001"; // aid
    NSArray *sids = @[@"279786",
                      @"275431",
                      @"279787",
                      @"280467",
                      @"280468",
                      @"280469",
                      @"274491",
                      @"267410",
                      @"267714",
                      @"270380",];
    NSString *sid = sids.count ? sids[arc4random_uniform((u_int32_t)sids.count)] : nil;
    NSString *accessKey = [NSClassFromString(@"BFCAccount") nj_accessKey];
    if (oid.length == 0 || sid.length == 0 ||
        accessKey.length == 0) {
        return;
    }
    NSDictionary *params = @{@"access_key" : accessKey,
                             @"oid" : oid,
                             @"panel_type" : @"1",
                             @"share_channel" : @"QQ",
                             @"share_id" : @"main.ugc-video-detail.0.0.pv",
                             @"share_origin" : @"vinfo_player",
                             @"sid" : sid,
                             @"success" : @"true",};
    
    BFCApiOptions *options = [NSClassFromString(@"BFCApiOptions") optionsWithBaseUrl:@"https://api.bilibili.com/x/share/finish"];
    // POST
    options.requestMethod = 1;
    options.params = params;
    BFCApiModelDescription *response_Des = [NSClassFromString(@"BFCApiModelDescription") modelWith:@"/" mappingClass:NSClassFromString(@"NJResponseModel") isArray:NO isOptional:YES];
    options.modelDescriptions = @[response_Des];
    BFCApiRequest *request = [(BFCApiRequest *)[NSClassFromString(@"BFCApiRequest") alloc] initWithOptions:options];
    request.completionHandler = ^(NSDictionary *dict) {
        if (completionHandler) {
            completionHandler(dict);
        }
    };
    request.errorHandler = ^(NSError *error, NSDictionary *dict) {
        if (errorHandler) {
            errorHandler(error, dict);
        }
    };
    
    [request requestAsync];
}
    
/// 从 BFCApiRequest 回调字典中取出业务 data
static NSDictionary *NJDataFromResponseDict(NSDictionary *dict) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id root = dict[@"/"];
    if ([root isKindOfClass:NSClassFromString(@"NJResponseModel")]) {
        return ((NJResponseModel *)root).data;
    }
    if ([root isKindOfClass:[NSDictionary class]]) {
        return root;
    }
    if ([dict[@"data"] isKindOfClass:[NSDictionary class]]) {
        return dict[@"data"];
    }
    return dict;
}

#pragma mark - 大积分

/// 加载大积分信息
+ (void)loadBigPointInfoWithCompletionHandler:(void (^ _Nullable)(NSInteger point, BOOL isSigned, NSInteger signCount))completionHandler
                                 errorHandler:(void (^ _Nullable)(NSError *error))errorHandler {
    BFCApiOptions *options = [NSClassFromString(@"BFCApiOptions") optionsWithBaseUrl:@"https://api.bilibili.com/x/vip/web/vip_center/v2"];
    options.params = @{};
    BFCApiModelDescription *response_Des = [NSClassFromString(@"BFCApiModelDescription") modelWith:@"/" mappingClass:NSClassFromString(@"NJResponseModel") isArray:NO isOptional:YES];
    options.modelDescriptions = @[response_Des];
    BFCApiRequest *request = [(BFCApiRequest *)[NSClassFromString(@"BFCApiRequest") alloc] initWithOptions:options];
    request.completionHandler = ^(NSDictionary *dict) {
        NSDictionary *data = NJDataFromResponseDict(dict);
        NSDictionary *bigPoint = [data[@"big_point"] isKindOfClass:[NSDictionary class]] ? data[@"big_point"] : nil;
        NSNumber *pointValue = [bigPoint[@"point"] isKindOfClass:[NSNumber class]] ? bigPoint[@"point"] : nil;
        NSDictionary *signInfo = [data[@"three_day_sign"] isKindOfClass:[NSDictionary class]] ? data[@"three_day_sign"] : nil;
        BOOL signedToday = [signInfo[@"signed"] boolValue];
        NSInteger signCount = [signInfo[@"count"] integerValue];
        if (pointValue) {
            NJBigPointCachedValue = pointValue.integerValue;
            dispatch_async(dispatch_get_main_queue(), ^{
                NJRefreshBigPointCoinLabel();
            });
        }
        if (completionHandler) {
            completionHandler(pointValue ? pointValue.integerValue : -1, signedToday, signCount);
        }
    };
    request.errorHandler = ^(NSError *error, NSDictionary *dict) {
        if (errorHandler) {
            errorHandler(error);
        }
    };
    [request requestAsync];
}

/// 会员中心大积分签到
+ (void)signBigPointWithCompletionHandler:(void (^ _Nullable)(BOOL success, NSString *message))completionHandler {
    BFCApiOptions *options = [NSClassFromString(@"BFCApiOptions") optionsWithBaseUrl:@"https://api.bilibili.com/pgc/activity/score/task/sign2"];
    options.requestMethod = 1;
    NSNumber *timestamp = @((long long)([[NSDate date] timeIntervalSince1970] * 1000));
    options.params = @{@"t": [timestamp stringValue]};
    options.extraHTTPHeader = @{@"Content-Type": @"application/json"};
    BFCApiModelDescription *response_Des = [NSClassFromString(@"BFCApiModelDescription") modelWith:@"/" mappingClass:NSClassFromString(@"NJResponseModel") isArray:NO isOptional:YES];
    options.modelDescriptions = @[response_Des];
    BFCApiRequest *request = [(BFCApiRequest *)[NSClassFromString(@"BFCApiRequest") alloc] initWithOptions:options];
    request.requestInjection = ^NSURLRequest *(NSURLRequest *req) {
        NSMutableURLRequest *mutableRequest = [req mutableCopy];
        [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSData *body = [NSJSONSerialization dataWithJSONObject:@{@"t": timestamp} options:0 error:nil];
        [mutableRequest setHTTPBody:body];
        return mutableRequest;
    };
    request.completionHandler = ^(NSDictionary *dict) {
        NSDictionary *data = NJDataFromResponseDict(dict);
        NSNumber *count = [data[@"count"] isKindOfClass:[NSNumber class]] ? data[@"count"] : nil;
        NSString *message = count ? [NSString stringWithFormat:@"签到成功，连续签到 %@ 天", count] : @"签到成功";
        if (completionHandler) {
            completionHandler(YES, message);
        }
        // 签到后刷新大积分数额
        [self loadBigPointInfoWithCompletionHandler:nil errorHandler:nil];
    };
    request.errorHandler = ^(NSError *error, NSDictionary *dict) {
        NSString *message = dict[@"message"];
        if (message.length == 0) {
            message = error.localizedDescription ?: @"签到失败，请稍后重试";
        }
        if (completionHandler) {
            completionHandler(NO, message);
        }
    };
    [request requestAsync];
}

/// 把大积分数额显示到「我的」页面的硬币 Label 旁边
+ (void)applyBigPointToCoinLabel:(UILabel *)coinLabel {
    if (![coinLabel isKindOfClass:[UILabel class]]) {
        return;
    }
    NJBigPointCoinLabel = coinLabel;
    NSString *text = coinLabel.text ?: @"";
    NSRange range = [text rangeOfString:@" · 大积分"];
    NJBigPointCoinBaseText = range.location != NSNotFound ? [text substringToIndex:range.location] : text;
    NJRefreshBigPointCoinLabel();
    // 首次展示时拉取大积分信息
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self loadBigPointInfoWithCompletionHandler:nil errorHandler:nil];
    });
}

@end
