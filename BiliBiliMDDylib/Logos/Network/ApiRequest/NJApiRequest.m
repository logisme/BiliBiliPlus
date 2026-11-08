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
/// 「我的」页面展示大积分的独立 Label（弱引用）
static __weak UILabel *NJBigPointValueLabel = nil;
/// 「我的」页面硬币 Label（弱引用）
static __weak UILabel *NJBigPointCoinLabel = nil;

/// 大积分 Label 使用的主题粉色
static UIColor *NJBigPointPinkColor(void) {
    return [UIColor colorWithRed:251.0 / 255.0
                           green:114.0 / 255.0
                            blue:153.0 / 255.0
                           alpha:1.0];
}

/// 确保大积分 Label 已添加到硬币 Label 所在的父视图
static UILabel *NJEnsureBigPointValueLabel(UILabel *coinLabel) {
    UIView *container = coinLabel.superview;
    if (!container) {
        return nil;
    }
    UILabel *label = NJBigPointValueLabel;
    if (label && label.superview == container) {
        return label;
    }
    [label removeFromSuperview];
    label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentLeft;
    label.lineBreakMode = NSLineBreakByClipping;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.5;
    label.userInteractionEnabled = NO;
    [container addSubview:label];
    NJBigPointValueLabel = label;
    return label;
}

/// 刷新大积分 Label 的文本
static void NJRefreshBigPointValueLabel(void) {
    UILabel *label = NJBigPointValueLabel;
    if (!label) {
        return;
    }
    if (NJBigPointCachedValue >= 0) {
        label.text = [NSString stringWithFormat:@"大积分：%ld", (long)NJBigPointCachedValue];
    } else {
        label.text = @"";
    }
    label.hidden = label.text.length == 0;
    [NJApiRequest layoutBigPointLabelInArea:label.superview];
}

@implementation NJApiRequest

/// 执行启动任务
+ (void)runLaunchTasks {
    static BOOL launchTasksStarted = NO;
    if (launchTasksStarted) {
        return;
    }
    // 用户未登录（登录态可能尚未加载完成，后续触发点会再次尝试）
    if (![NSClassFromString(@"BFCAccount") nj_isLogin]) {
        return;
    }
    launchTasksStarted = YES;

    // 领取手动选择的大会员福利
    [self couponAutoReceiver];

    // 大积分自动签到：每次启动都检查一次，已签到直接静默返回，不弹窗
    [self signBigPointWithCompletionHandler:^(BOOL success, NSString *message) {
        if (success || [message containsString:@"已签到"]) {
            [[NJDailyTaskManager shared] markTaskDone:NJ_BIG_POINT_SIGN_KEY];
        }
    }];
    
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
    
#pragma mark - 大积分

/// 收集 B 站 Cookie
static NSDictionary<NSString *, NSString *> *NJBigPointCookiesDictionary(void) {
    NSMutableDictionary<NSString *, NSString *> *cookieDict = [NSMutableDictionary dictionary];
    // 1. 账号 SSO 中保存的 Cookie
    @try {
        id ssoModel = [NSClassFromString(@"BFCAccount") currentSSO];
        id cookieInfo = [ssoModel valueForKey:@"cookieInfo"];
        NSArray *cookies = [cookieInfo valueForKey:@"cookies"];
        if ([cookies isKindOfClass:[NSArray class]]) {
            for (id cookie in cookies) {
                NSString *name = [cookie valueForKey:@"name"];
                NSString *value = [cookie valueForKey:@"value"];
                if ([name isKindOfClass:[NSString class]] && name.length > 0 &&
                    [value isKindOfClass:[NSString class]] && value.length > 0) {
                    cookieDict[name] = value;
                }
            }
        }
    } @catch (__unused NSException *exception) {
    }
    // 2. NSHTTPCookieStorage 中的 bilibili Cookie（补充 buvid3/buvid4 等）
    NSArray<NSHTTPCookie *> *storageCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"https://api.bilibili.com"]];
    for (NSHTTPCookie *cookie in storageCookies) {
        if (cookie.name.length > 0 && cookie.value.length > 0) {
            cookieDict[cookie.name] = cookie.value;
        }
    }
    // 3. 兜底补充
    NSString *sessdata = [NSClassFromString(@"BFCAccount") nj_getCookieSESSDATA];
    NSString *biliJct = [NSClassFromString(@"BFCAccount") nj_getCookieBiliJct];
    if (cookieDict[@"SESSDATA"].length == 0 && sessdata.length > 0) {
        cookieDict[@"SESSDATA"] = sessdata;
    }
    if (cookieDict[@"bili_jct"].length == 0 && biliJct.length > 0) {
        cookieDict[@"bili_jct"] = biliJct;
    }
    return cookieDict;
}

/// 大积分相关请求使用的 Cookie
static NSString *NJBigPointCookieString(void) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    NSDictionary<NSString *, NSString *> *cookieDict = NJBigPointCookiesDictionary();
    for (NSString *name in cookieDict) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@", name, cookieDict[name]]];
    }
    return [parts componentsJoinedByString:@"; "];
}

/// 大积分请求使用的 buvid
static NSString *NJBigPointBuvid(void) {
    NSDictionary<NSString *, NSString *> *cookieDict = NJBigPointCookiesDictionary();
    NSString *buvid = cookieDict[@"buvid3"];
    if (buvid.length == 0) {
        buvid = cookieDict[@"buvid"];
    }
    return buvid ?: @"";
}

/// 大积分 H5 页面 Referer
#define NJ_BIG_POINT_REFERER @"https://big.bilibili.com/mobile/bigPoint?closable=1&msource=0"

/// 大积分 GET 请求
static void NJBigPointGET(NSString *urlString,
                          NSString *cookie,
                          NSString *referer,
                          void (^handler)(NSDictionary *json)) {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.timeoutInterval = 15.0;
    [request setValue:cookie forHTTPHeaderField:@"Cookie"];
    [request setValue:referer forHTTPHeaderField:@"Referer"];
    [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1" forHTTPHeaderField:@"User-Agent"];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            handler(nil);
            return;
        }
        id json = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        handler([json isKindOfClass:[NSDictionary class]] ? json : nil);
    }];
    [task resume];
}

/// 加载大积分信息
+ (void)loadBigPointInfoWithCompletionHandler:(void (^ _Nullable)(NSInteger point, BOOL isSigned, NSInteger signCount))completionHandler
                                 errorHandler:(void (^ _Nullable)(NSError *error))errorHandler {
    NSString *cookie = NJBigPointCookieString();
    NSString *accessKey = [NSClassFromString(@"BFCAccount") nj_accessKey];
    if (cookie.length == 0 && accessKey.length == 0) {
        if (errorHandler) {
            errorHandler([NSError errorWithDomain:@"NJBigPoint" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"未登录"}]);
        }
        return;
    }
    NSString *biliJct = [NSClassFromString(@"BFCAccount") nj_getCookieBiliJct];
    NSString *buvid = NJBigPointBuvid();
    // 大积分余额接口（与 BiliBiliToolPro 使用的一致）
    NSString *combineURL = [NSString stringWithFormat:@"https://api.bilibili.com/x/vip_point/task/combine?csrf=%@", biliJct];
    if (buvid.length > 0) {
        combineURL = [combineURL stringByAppendingFormat:@"&buvid=%@", buvid];
    }
    NJBigPointGET(combineURL, cookie, @"https://big.bilibili.com/mobile/bigPoint/task", ^(NSDictionary *json) {
        NSDictionary *dataDic = [json[@"data"] isKindOfClass:[NSDictionary class]] ? json[@"data"] : nil;
        NSDictionary *pointInfo = [dataDic[@"point_info"] isKindOfClass:[NSDictionary class]] ? dataDic[@"point_info"] : nil;
        NSNumber *pointValue = [pointInfo[@"point"] isKindOfClass:[NSNumber class]] ? pointInfo[@"point"] : nil;
        if (pointValue) {
            NJBigPointCachedValue = pointValue.integerValue;
            dispatch_async(dispatch_get_main_queue(), ^{
                NJRefreshBigPointValueLabel();
            });
            if (completionHandler) {
                completionHandler(pointValue.integerValue, NO, 0);
            }
            return;
        }
        // 兜底：会员中心 v2 接口
        NSString *mid = [NSString stringWithFormat:@"%lld", NJ_MID];
        NSString *urlString = [NSString stringWithFormat:@"https://api.bilibili.com/x/vip/web/vip_center/v2?mid=%@&build=9180000&mobi_app=iphone&platform=ios", mid];
        if (accessKey.length > 0) {
            urlString = [urlString stringByAppendingFormat:@"&access_key=%@", accessKey];
        }
        NJBigPointGET(urlString, cookie, NJ_BIG_POINT_REFERER, ^(NSDictionary *json2) {
            NSDictionary *data2 = [json2[@"data"] isKindOfClass:[NSDictionary class]] ? json2[@"data"] : nil;
            NSDictionary *bigPoint = [data2[@"big_point"] isKindOfClass:[NSDictionary class]] ? data2[@"big_point"] : nil;
            NSNumber *point2 = [bigPoint[@"point"] isKindOfClass:[NSNumber class]] ? bigPoint[@"point"] : nil;
            NSDictionary *signInfo = [data2[@"three_day_sign"] isKindOfClass:[NSDictionary class]] ? data2[@"three_day_sign"] : nil;
            if (point2) {
                NJBigPointCachedValue = point2.integerValue;
                dispatch_async(dispatch_get_main_queue(), ^{
                    NJRefreshBigPointValueLabel();
                });
            }
            if (completionHandler) {
                completionHandler(point2 ? point2.integerValue : -1,
                                  [signInfo[@"signed"] boolValue],
                                  [signInfo[@"count"] integerValue]);
            }
        });
    });
}

/// 发送大积分签到请求（与 BiliBiliToolPro 保持一致的请求格式）
static void NJBigPointSignRequest(NSString *cookie,
                                  NSString *buvid,
                                  NSString *biliJct,
                                  void (^handler)(NSInteger code, NSString *message, NSDictionary *data)) {
    NSString *urlString = [NSString stringWithFormat:@"https://api.bilibili.com/pgc/activity/score/task/sign2?mobi_app=android&csrf=%@&platform=android", biliJct];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 15.0;
    [request setValue:cookie forHTTPHeaderField:@"Cookie"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"https://big.bilibili.com/mobile/index" forHTTPHeaderField:@"Referer"];
    [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1" forHTTPHeaderField:@"User-Agent"];
    if (buvid.length > 0) {
        [request setValue:buvid forHTTPHeaderField:@"buvid"];
    }
    NSNumber *timestamp = @((long long)([[NSDate date] timeIntervalSince1970] * 1000));
    NSDictionary *body = @{@"t": timestamp,
                           @"device": @"phone",
                           @"ts": @(timestamp.longLongValue / 1000)};
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        id json = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if (error || ![json isKindOfClass:[NSDictionary class]]) {
            handler(-999, error.localizedDescription ?: @"网络请求失败", nil);
            return;
        }
        NSInteger code = [json[@"code"] integerValue];
        NSString *message = [json[@"message"] isKindOfClass:[NSString class]] ? json[@"message"] : @"";
        NSDictionary *dataDic = [json[@"data"] isKindOfClass:[NSDictionary class]] ? json[@"data"] : nil;
        handler(code, message, dataDic);
    }];
    [task resume];
}

/// 会员中心大积分签到（使用 H5 同款 Cookie 请求，避免「非法访问」）
+ (void)signBigPointWithCompletionHandler:(void (^ _Nullable)(BOOL success, NSString *message))completionHandler {
    NSString *cookie = NJBigPointCookieString();
    NSString *biliJct = [NSClassFromString(@"BFCAccount") nj_getCookieBiliJct];
    NSString *accessKey = [NSClassFromString(@"BFCAccount") nj_accessKey];
    if (cookie.length == 0 && accessKey.length == 0) {
        if (completionHandler) {
            completionHandler(NO, @"未登录，无法签到");
        }
        return;
    }
    NSString *buvid = NJBigPointBuvid();
    // 先查询今日是否已签到
    NSString *signInfoURL = [NSString stringWithFormat:@"https://api.bilibili.com/x/vip/vip_center/sign_in/three_days_sign?csrf=%@", biliJct];
    NJBigPointGET(signInfoURL, cookie, @"https://big.bilibili.com/mobile/bigPoint/task", ^(NSDictionary *json) {
        NSDictionary *dataDic = [json[@"data"] isKindOfClass:[NSDictionary class]] ? json[@"data"] : nil;
        NSDictionary *signInfo = [dataDic[@"three_day_sign"] isKindOfClass:[NSDictionary class]] ? dataDic[@"three_day_sign"] : nil;
        if ([signInfo[@"signed"] boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandler) {
                    completionHandler(YES, @"今日已签到");
                }
            });
            [self loadBigPointInfoWithCompletionHandler:nil errorHandler:nil];
            return;
        }
        NJBigPointSignRequest(cookie, buvid, biliJct, ^(NSInteger code, NSString *message, NSDictionary *data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (code == 0) {
                    NSNumber *count = [data[@"count"] isKindOfClass:[NSNumber class]] ? data[@"count"] : nil;
                    NSString *text = count ? [NSString stringWithFormat:@"签到成功，连续签到 %@ 天", count] : @"签到成功";
                    if (completionHandler) {
                        completionHandler(YES, text);
                    }
                    [self loadBigPointInfoWithCompletionHandler:nil errorHandler:nil];
                } else {
                    NSString *text = message.length > 0 ? message : @"签到失败，请稍后重试";
                    if (completionHandler) {
                        completionHandler(NO, text);
                    }
                }
            });
        });
    });
}

/// 最近一次拉取大积分的时间
static NSTimeInterval NJBigPointLastFetchTime = 0;

/// 把大积分数额作为独立 Label 显示在「我的」页面的硬币旁边
+ (void)applyBigPointToCoinLabel:(UILabel *)coinLabel {
    if (![coinLabel isKindOfClass:[UILabel class]]) {
        return;
    }
    NJBigPointCoinLabel = coinLabel;
    UILabel *valueLabel = NJEnsureBigPointValueLabel(coinLabel);
    if (valueLabel) {
        valueLabel.font = coinLabel.font ?: [UIFont systemFontOfSize:12.0];
        valueLabel.textColor = coinLabel.textColor ?: NJBigPointPinkColor();
    }
    NJRefreshBigPointValueLabel();
    // 尚未拿到数额时拉取（失败后 30 秒可重试，避免一直空白）
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (NJBigPointCachedValue < 0 && now - NJBigPointLastFetchTime > 30) {
        NJBigPointLastFetchTime = now;
        [self loadBigPointInfoWithCompletionHandler:nil errorHandler:nil];
    }
}

/// 在「我的」页面重新排列硬币与大积分 Label（B币、硬币、大积分保持平级）
+ (void)layoutBigPointLabelInArea:(UIView *)area {
    (void)area;
    UILabel *coinLabel = NJBigPointCoinLabel;
    if (![coinLabel isKindOfClass:[UILabel class]]) {
        return;
    }
    UIView *container = coinLabel.superview;
    if (!container) {
        return;
    }
    UILabel *valueLabel = NJEnsureBigPointValueLabel(coinLabel);
    if (!valueLabel) {
        return;
    }
    CGRect coinFrame = coinLabel.frame;
    if (coinFrame.size.width <= 0 || coinFrame.size.height <= 0) {
        return;
    }

    valueLabel.hidden = valueLabel.text.length == 0;
    if (valueLabel.hidden) {
        return;
    }

    valueLabel.font = coinLabel.font ?: [UIFont systemFontOfSize:12.0];
    valueLabel.textColor = coinLabel.textColor ?: NJBigPointPinkColor();

    CGFloat rightLimit = CGRectGetWidth(container.bounds) - 8.0;
    for (UIView *sibling in container.subviews) {
        if (sibling == valueLabel || sibling == coinLabel) {
            continue;
        }
        if (sibling.hidden || sibling.alpha < 0.01) {
            continue;
        }
        CGRect frame = sibling.frame;
        if (frame.size.width <= 0 || frame.size.height <= 0) {
            continue;
        }
        // 只避让与硬币同一行、位于其右侧的控件（如「个人空间」入口）
        if (CGRectGetMinX(frame) <= CGRectGetMaxX(coinFrame)) {
            continue;
        }
        if (CGRectGetMidY(frame) < CGRectGetMinY(coinFrame) - 2.0 ||
            CGRectGetMidY(frame) > CGRectGetMaxY(coinFrame) + 2.0) {
            continue;
        }
        rightLimit = MIN(rightLimit, CGRectGetMinX(frame) - 6.0);
    }

    // 复用 B币 / 硬币 Label 之间的原始间距，保证三个 Label 视觉间距一致
    CGFloat gap = 8.0;
    @try {
        id bCoinObject = [container valueForKey:@"bCoinLbl"];
        if ([bCoinObject isKindOfClass:[UILabel class]]) {
            UILabel *bCoinLabel = (UILabel *)bCoinObject;
            CGRect bCoinFrame = bCoinLabel.frame;
            BOOL sameRow = !bCoinLabel.hidden &&
                           CGRectGetWidth(bCoinFrame) > 0 &&
                           fabs(CGRectGetMidY(bCoinFrame) - CGRectGetMidY(coinFrame)) < 2.0 &&
                           CGRectGetMaxX(bCoinFrame) <= CGRectGetMinX(coinFrame) + 1.0;
            if (sameRow) {
                CGFloat originalGap = CGRectGetMinX(coinFrame) - CGRectGetMaxX(bCoinFrame);
                if (originalGap >= 2.0 && originalGap <= 20.0) {
                    gap = originalGap;
                }
            }
        }
    } @catch (__unused NSException *exception) {
    }
    CGFloat x = CGRectGetMaxX(coinFrame) + gap;
    CGFloat available = rightLimit - x;
    CGSize naturalSize = [valueLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, coinFrame.size.height)];

    if (available < naturalSize.width && available > 0) {
        CGFloat scale = MAX(0.6, available / naturalSize.width);
        UIFont *font = valueLabel.font;
        valueLabel.font = [UIFont fontWithDescriptor:font.fontDescriptor
                                                size:font.pointSize * scale];
        naturalSize = [valueLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, coinFrame.size.height)];
    }

    if (available < 40.0) {
        // 横向空间实在不足时换到硬币下一行，保证内容完整可见
        CGFloat y = CGRectGetMaxY(coinFrame) + 2.0;
        CGFloat maxWidth = CGRectGetWidth(container.bounds) - CGRectGetMinX(coinFrame) - 8.0;
        valueLabel.frame = CGRectMake(CGRectGetMinX(coinFrame),
                                      y,
                                      MIN(naturalSize.width, MAX(maxWidth, 0.0)),
                                      naturalSize.height);
        return;
    }
    valueLabel.frame = CGRectMake(x,
                                  coinFrame.origin.y,
                                  MIN(naturalSize.width, available),
                                  coinFrame.size.height);
}

@end
