// 主页-推荐的广告

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "NJCommonDefine.h"
#import "NJApiRequest.h"

%group App

// 评分弹窗
%hook BFCStoreScorePopupManager

+ (void)showWithNeed:(id)need close:(id)close {
    
}

+ (void)showFromJSBWithNeed:(id)need close:(id)close {
    
}

+ (void)showWithParam:(id)param need:(id)need close:(id)close {
    
}

- (void)showWithAttentionCount:(unsigned long long)attentionCount shareCount:(unsigned long long)shareCount likeCount:(unsigned long long)likeCount watchVideoCount:(unsigned long long)watchVideoCount popperConfig:(id)config {
    
}

%end

// 打开推送通知弹窗
%hook BFCPushGuideSheetView

- (id)initWithModel:(id)model delegate:(id)delegate spmid:(id)spmid {
    return nil;
}

%end

// +号气泡弹窗，比如提示二次元妆造挑战
%hook BBPhoneTabBarBubbleView

- (id)initWithFrame:(CGRect)frame {
    return nil;
}

%end

// 未成年人模式弹窗
%hook BFCRestrictedModeTeenagersAlertView

// 是否显示未成年人模式弹窗
+ (BOOL)needShowTeenagersAlert {
    return NO;
}

%end

// 首页-推荐视图控制器
%hook BBPegasusViewController

- (void)viewDidLoad {
    %orig;
    // 执行启动任务
    [NJApiRequest runLaunchTasks];
}

%end

// 9.18 首页推荐视图控制器（BBPegasusViewController 的替代实现）
%hook BBHD2PhonePegasusMainV2VC

- (void)viewDidLoad {
    %orig;
    // 执行启动任务
    [NJApiRequest runLaunchTasks];
}

%end

#pragma mark - 首页 Pegasus 大卡片广告

/// 判断类名是否属于广告卡片模型（覆盖 9.18 的 BBAdPegasus 系列）
static BOOL NJPegasusClassIsAd(NSString *className) {
    if (className.length == 0) {
        return NO;
    }
    NSArray<NSString *> *markers = @[
        @"PegasusAd",       // 旧版 Pegasus 广告模型
        @"AdSingle",        // 单卡片广告
        @"AdBaseModel",     // 广告基础模型
        @"AdInfoModel",     // 广告信息模型
        @"MPAdContainer",   // 广告容器
        @"AdPG",            // 9.18 广告卡片（AdPGBaseViewModel / AdPGBaseCell）
        @"BBAdPegasus",     // 9.18 广告模块
        @"AdEmptyCard",     // 广告占位卡片
        @"BannerItem",      // TopView / Banner 广告（BannerItemViewModel）
        @"BannerV8",        // Banner 广告卡片
        @"BannerTopView",   // 顶部焦点图广告
        @"CMV2Card",        // cm_v2_card_* 广告卡片
        @"CMSingleV",       // cm_single_v* 广告卡片
        @"CMDoubleV",       // cm_double_v* 广告卡片
        @"TopView",         // 顶部焦点图广告
        @"StoryAd",         // 竖屏故事广告
        @"AdInline",        // 视频内嵌广告
        @"AdMall",          // 会员购推广卡片（AdMallGoodsCardModel 等）
        @"BBAdMall",        // 会员购广告模块
        @"AdGoodsCard",     // 会员购商品卡片
        @"AdRecommendCard"  // 会员购推荐卡片
    ];
    for (NSString *marker in markers) {
        if ([className containsString:marker]) {
            return YES;
        }
    }
    return NO;
}

/// 判断字符串是否指向会员购 / 商业推广落地页
static BOOL NJPegasusStringIsAdLink(NSString *value) {
    if (![value isKindOfClass:[NSString class]] || value.length == 0) {
        return NO;
    }
    NSString *lower = value.lowercaseString;
    BOOL isLink = [lower hasPrefix:@"http://"] ||
                  [lower hasPrefix:@"https://"] ||
                  [lower hasPrefix:@"bilibili://"];
    return [lower containsString:@"mall.bilibili.com"] ||
           [lower containsString:@"bilibili://mall"] ||
           [lower containsString:@"cm.bilibili.com"] ||
           [lower isEqualToString:@"mall"] ||
           [lower isEqualToString:@"ad"] ||
           (isLink && ([lower containsString:@"mall/home"] ||
                       [lower containsString:@"/mall/"]));
}

/// 递归检查对象中是否包含广告 / 会员购特征
static BOOL NJPegasusObjectContainsMallAd(id object, NSInteger depth) {
    if (!object || depth > 5) {
        return NO;
    }
    if ([object isKindOfClass:[NSNumber class]] || [object isKindOfClass:[NSNull class]]) {
        return NO;
    }
    if ([object isKindOfClass:[NSString class]]) {
        return NJPegasusStringIsAdLink((NSString *)object);
    }
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        for (id key in dict) {
            NSString *keyName = [key isKindOfClass:[NSString class]] ? (NSString *)key : @"";
            if ([keyName isEqualToString:@"ad_cb"] ||
                [keyName isEqualToString:@"ad_info"] ||
                [keyName isEqualToString:@"adInfo"] ||
                [keyName isEqualToString:@"hasAdInfo"] ||
                [keyName isEqualToString:@"ad_type"] ||
                [keyName isEqualToString:@"cm_stock"] ||
                [keyName isEqualToString:@"cmStock"] ||
                [keyName isEqualToString:@"cm_info"] ||
                [keyName isEqualToString:@"cmInfo"] ||
                [keyName isEqualToString:@"is_ad"] ||
                [keyName isEqualToString:@"isAd"] ||
                [keyName isEqualToString:@"banner_item"] ||
                [keyName isEqualToString:@"bannerItem"] ||
                [keyName isEqualToString:@"topview"] ||
                [keyName isEqualToString:@"top_view"]) {
                return YES;
            }
            if (NJPegasusObjectContainsMallAd(dict[key], depth + 1)) {
                return YES;
            }
        }
        return NO;
    }
    if ([object isKindOfClass:[NSArray class]]) {
        for (id value in (NSArray *)object) {
            if (NJPegasusObjectContainsMallAd(value, depth + 1)) {
                return YES;
            }
        }
        return NO;
    }

    // 普通模型对象：检查广告标识与会员购落地页字段
    NSString *className = NSStringFromClass([object class]);
    if (NJPegasusClassIsAd(className)) {
        return YES;
    }
    @try {
        id hasAdInfo = [object valueForKey:@"hasAdInfo"];
        if ([hasAdInfo isKindOfClass:[NSNumber class]] && [hasAdInfo boolValue]) {
            return YES;
        }
    } @catch (__unused NSException *exception) {
    }
    NSArray<NSString *> *nestedKeys = @[@"adInfo", @"base", @"model", @"cardBaseVO",
                                        @"card_base_vo", @"cardGoto", @"goto_p",
                                        @"cardType", @"card_type", @"uri", @"args"];
    for (NSString *key in nestedKeys) {
        @try {
            id value = [object valueForKey:key];
            if (!value || value == object || [value isKindOfClass:[NSNull class]]) {
                continue;
            }
            if ([key isEqualToString:@"cardType"] || [key isEqualToString:@"card_type"]) {
                if ([value isKindOfClass:[NSString class]]) {
                    NSString *lower = [(NSString *)value lowercaseString];
                    if ([lower hasPrefix:@"cm_"] ||
                        [lower containsString:@"cm_single"] ||
                        [lower containsString:@"cm_v2"] ||
                        [lower containsString:@"cm_double"] ||
                        [lower hasPrefix:@"banner"]) {
                        return YES;
                    }
                }
                continue;
            }
            if (NJPegasusObjectContainsMallAd(value, depth + 1)) {
                return YES;
            }
        } @catch (__unused NSException *exception) {
        }
    }

    // 遍历 GPB 卡片包装类的字段（如 BAPIAppCardV1Card 的 smallCoverV5 / smallCoverV5Ad）
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList([object class], &propertyCount);
    BOOL found = NO;
    for (unsigned int i = 0; i < propertyCount && !found; i++) {
        const char *propertyName = property_getName(properties[i]);
        if (!propertyName) {
            continue;
        }
        NSString *key = [NSString stringWithUTF8String:propertyName];
        if (key.length == 0 ||
            [key hasPrefix:@"has"] ||
            [key hasSuffix:@"_Count"] ||
            [key isEqualToString:@"itemOneOfCase"] ||
            [key isEqualToString:@"descriptor"] ||
            [key isEqualToString:@"unknownFields"]) {
            continue;
        }
        @try {
            id value = [object valueForKey:key];
            if (!value || value == object || [value isKindOfClass:[NSNull class]]) {
                continue;
            }
            // smallCoverV5Ad 等专门的广告卡字段，非空即视为广告
            if ([key hasSuffix:@"Ad"]) {
                found = YES;
                break;
            }
            if (NJPegasusObjectContainsMallAd(value, depth + 1)) {
                found = YES;
                break;
            }
        } @catch (__unused NSException *exception) {
        }
    }
    if (properties) {
        free(properties);
    }
    return found;
}

// 过滤 Pegasus 广告模型（会员购、广告大卡片、TopView 等）
static NSArray *NJFilterPegasusAdModels(NSArray *models) {
    if (![models isKindOfClass:[NSArray class]]) {
        return models;
    }
    NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:models.count];
    for (id model in models) {
        NSString *className = NSStringFromClass([model class]);
        if (NJPegasusClassIsAd(className)) {
            continue;
        }
        [filtered addObject:model];
    }
    return filtered;
}

// 模型解析入口：输入是 GPB 卡片数据，输出是 ViewModel，两层都剔除广告
%hook BBHD2PhonePegasusModelBaseHelper

- (NSArray *)dataArrayFromArray:(NSArray *)array {
    NSArray *filteredInput = NJFilterPegasusAdModels(array);
    NSArray *models = %orig(filteredInput);
    return NJFilterPegasusAdModels(models);
}

- (NSArray *)dataArrayFromArray:(NSArray *)array modelAnalysisCallback:(id)callback {
    NSArray *filteredInput = NJFilterPegasusAdModels(array);
    NSArray *models = %orig(filteredInput, callback);
    return NJFilterPegasusAdModels(models);
}

%end

// 卡片池兜底：同样剔除广告模型
%hook BBHD2PegasusCardPool

+ (NSArray *)dataArrayFromArray:(NSArray *)array modelAnalysisCallback:(id)callback {
    NSArray *filteredInput = NJFilterPegasusAdModels(array);
    NSArray *models = %orig(filteredInput, callback);
    return NJFilterPegasusAdModels(models);
}

%end

// 广告大卡片兜底：即使漏过模型过滤，也不展示（高度置 0）
%hook BBHD2PhonePegasusAdSingleCell

- (void)didMoveToWindow {
    %orig;
    ((UIView *)self).hidden = YES;
}

+ (CGFloat)getHeightWithObject:(id)object argv:(id)argv {
    return 0.0;
}

%end

%hook BBHD2PhonePegasusAdSingleDislikeCell

- (void)didMoveToWindow {
    %orig;
    ((UIView *)self).hidden = YES;
}

+ (CGFloat)getHeightWithObject:(id)object argv:(id)argv {
    return 0.0;
}

%end

#pragma mark - 首页 Pegasus 卡片模型级广告过滤

@interface BBHD2PhonePegasusMainVM : NSObject
@end

@interface BBHD2PhonePegasusBaseListVM : NSObject
@end

/// 判断 Pegasus 卡片模型是否属于广告
static BOOL NJPegasusObjectIsAd(id object) {
    if (!object) {
        return NO;
    }
    // 统一走递归检查：兼容字典、数组、GPB 卡片模型与 Swift ViewModel
    if (NJPegasusObjectContainsMallAd(object, 0)) {
        return YES;
    }
    if ([object isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    NSString *className = NSStringFromClass([object class]);
    if (NJPegasusClassIsAd(className)) {
        return YES;
    }

    // 广告标记字段：非空即视为广告
    NSArray<NSString *> *adFlagKeys = @[@"bbad_model", @"bbad_is_ad", @"is_ad", @"isAd",
                                        @"ad_info", @"adInfo", @"cm_info", @"cmInfo",
                                        @"cm_reason_id", @"ad_cb", @"bbad_ad_cb",
                                        @"adpginfo", @"adPgInfo", @"ad_pg_info",
                                        @"banner_item", @"bannerItem", @"topview", @"top_view"];
    for (NSString *key in adFlagKeys) {
        @try {
            id value = [object valueForKey:key];
            if (!value || [value isKindOfClass:[NSNull class]]) {
                continue;
            }
            if ([value isKindOfClass:[NSNumber class]]) {
                if ([value boolValue]) {
                    return YES;
                }
            } else {
                return YES;
            }
        } @catch (__unused NSException *exception) {
        }
    }

    // 落地页 / 卡片类型字段：只有确实指向会员购或广告时才过滤
    NSArray<NSString *> *adContentKeys = @[@"card_goto", @"cardGoto", @"goto", @"uri",
                                           @"jump_url", @"jumpUrl", @"args", @"cardBaseVO",
                                           @"card_base_vo", @"card_type", @"cardType"];
    for (NSString *key in adContentKeys) {
        @try {
            id value = [object valueForKey:key];
            if (!value || [value isKindOfClass:[NSNull class]]) {
                continue;
            }
            if ([key isEqualToString:@"card_type"] || [key isEqualToString:@"cardType"]) {
                if ([value isKindOfClass:[NSString class]]) {
                    NSString *lower = [(NSString *)value lowercaseString];
                    if ([lower hasPrefix:@"cm_"] ||
                        [lower containsString:@"cm_single"] ||
                        [lower containsString:@"cm_v2"] ||
                        [lower containsString:@"cm_double"] ||
                        [lower hasPrefix:@"banner"]) {
                        return YES;
                    }
                }
                continue;
            }
            if ([value isKindOfClass:[NSString class]]) {
                if (NJPegasusStringIsAdLink((NSString *)value)) {
                    return YES;
                }
                continue;
            }
            if (NJPegasusObjectContainsMallAd(value, 0)) {
                return YES;
            }
        } @catch (__unused NSException *exception) {
        }
    }
    return NO;
}

/// 过滤广告卡片模型
static NSArray *NJFilterPegasusAdCards(NSArray *array) {
    if (![array isKindOfClass:[NSArray class]]) {
        return array;
    }
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:array.count];
    for (id object in array) {
        if (NJPegasusObjectIsAd(object)) {
            continue;
        }
        [result addObject:object];
    }
    return result;
}

// 首页推荐构建卡片数组时剔除广告卡片
%hook BBHD2PhonePegasusMainVM

- (void)buildObjectsWithNewArray:(NSArray *)array clearOld:(BOOL)clearOld {
    %orig(NJFilterPegasusAdCards(array), clearOld);
}

%end

// 列表数据源兜底：新增/替换卡片时同样剔除广告
%hook BBHD2PhonePegasusBaseListVM

- (void)addObjectsFromArray:(NSArray *)array {
    %orig(NJFilterPegasusAdCards(array));
}

- (void)addObjectsFromArray:(NSArray *)array removeDuplicate:(BOOL)removeDuplicate {
    %orig(NJFilterPegasusAdCards(array), removeDuplicate);
}

- (void)setObjects:(NSArray *)objects {
    %orig(NJFilterPegasusAdCards(objects));
}

%end

#pragma mark - 我的页面大积分

@interface BBPhoneMineInfoArea : UIView
@end

@interface BBPhoneUserCenterVC : UIViewController
@end

@interface BBPhoneMineGridCell : UIView
@end

@interface BBPhoneMineEnterCell : UIView
@end

@interface BBPhoneMineItemCell : UIView
@end

static void NJApplyBigPointToMineArea(id area) {
    id coinLabel = nil;
    @try {
        coinLabel = [area valueForKey:@"coinLbl"];
    } @catch (__unused NSException *exception) {
    }
    if ([coinLabel isKindOfClass:[UILabel class]]) {
        [NJApiRequest applyBigPointToCoinLabel:(UILabel *)coinLabel];
    }
}

// 递归查找包含指定文本的 Label
static BOOL NJViewContainsLabelText(UIView *view, NSString *text) {
    if (!view || text.length == 0) {
        return NO;
    }
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if (label.text.length > 0 && [label.text containsString:text]) {
            return YES;
        }
    }
    for (UIView *subview in view.subviews) {
        if (NJViewContainsLabelText(subview, text)) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - QQ 分享 BundleID 兼容

/// B 站官方的 BundleID，QQ 开放平台校验时使用这个值
static NSString * const NJBilibiliOfficialBundleID = @"tv.danmaku.bilianime";
/// QQ SDK 构建请求时临时强制返回官方 BundleID 的深度
static NSInteger NJQQBundleOverrideDepth = 0;

static void NJQQBeginBundleOverride(void) {
    NJQQBundleOverrideDepth += 1;
}

static void NJQQEndBundleOverride(void) {
    if (NJQQBundleOverrideDepth > 0) {
        NJQQBundleOverrideDepth -= 1;
    }
}

/// 修正 QQ 请求中的 BundleID（重签名后 BundleID 可能被修改，导致 QQ 报 25103 非官方 app）
static void NJQQFixQueryItem(id item) {
    if (!item) {
        return;
    }
    NSString *actualBundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (actualBundleID.length == 0 ||
        [actualBundleID isEqualToString:NJBilibiliOfficialBundleID]) {
        return;
    }

    if ([item isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *dictionary = (NSMutableDictionary *)item;
        for (id key in [dictionary allKeys]) {
            NSString *keyString = [key isKindOfClass:[NSString class]] ? (NSString *)key : @"";
            NSString *lowerKey = keyString.lowercaseString;
            id value = dictionary[key];
            if ([lowerKey containsString:@"bundle"]) {
                dictionary[key] = NJBilibiliOfficialBundleID;
            } else if ([value isKindOfClass:[NSString class]] &&
                       [(NSString *)value containsString:actualBundleID]) {
                dictionary[key] = [(NSString *)value stringByReplacingOccurrencesOfString:actualBundleID
                                                                               withString:NJBilibiliOfficialBundleID];
            } else {
                NJQQFixQueryItem(value);
            }
        }
        return;
    }

    if ([item isKindOfClass:[NSMutableArray class]]) {
        NSMutableArray *array = (NSMutableArray *)item;
        for (NSUInteger i = 0; i < array.count; i++) {
            id value = array[i];
            if ([value isKindOfClass:[NSURLQueryItem class]]) {
                NSURLQueryItem *queryItem = (NSURLQueryItem *)value;
                NSString *name = queryItem.name ?: @"";
                if ([name.lowercaseString containsString:@"bundle"]) {
                    array[i] = [NSURLQueryItem queryItemWithName:name
                                                           value:NJBilibiliOfficialBundleID];
                } else if (queryItem.value &&
                           [queryItem.value containsString:actualBundleID]) {
                    array[i] = [NSURLQueryItem queryItemWithName:name
                                                           value:[queryItem.value stringByReplacingOccurrencesOfString:actualBundleID
                                                                                                             withString:NJBilibiliOfficialBundleID]];
                }
            } else {
                NJQQFixQueryItem(value);
            }
        }
    }
}

/// 修正 QQ 请求 URL 中残留的实际 BundleID
static id NJQQFixURLValue(id value) {
    NSString *actualBundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (actualBundleID.length == 0 ||
        [actualBundleID isEqualToString:NJBilibiliOfficialBundleID]) {
        return value;
    }
    NSString *string = nil;
    if ([value isKindOfClass:[NSURL class]]) {
        string = [(NSURL *)value absoluteString];
    } else if ([value isKindOfClass:[NSString class]]) {
        string = (NSString *)value;
    }
    if (string.length == 0 || ![string containsString:actualBundleID]) {
        return value;
    }
    NSString *fixedString = [string stringByReplacingOccurrencesOfString:actualBundleID
                                                             withString:NJBilibiliOfficialBundleID];
    if ([value isKindOfClass:[NSURL class]]) {
        return [NSURL URLWithString:fixedString] ?: value;
    }
    return fixedString;
}

/// QQ SDK 内部读取 BundleID 时临时返回官方值，保证请求和签名参数一致
%hook NSBundle

- (NSString *)bundleIdentifier {
    NSString *identifier = %orig;
    if (NJQQBundleOverrideDepth > 0) {
        return NJBilibiliOfficialBundleID;
    }
    return identifier;
}

%end

%hook QQApiMessageAndUrlConverter

+ (void)setString:(NSString *)value forKey:(NSString *)key toQueryItem:(id)queryItem {
    NSString *fixedValue = value;
    if ([key isKindOfClass:[NSString class]] &&
        [key.lowercaseString containsString:@"bundle"]) {
        fixedValue = NJBilibiliOfficialBundleID;
    }
    NJQQBeginBundleOverride();
    @try {
        %orig(fixedValue, key, queryItem);
    } @finally {
        NJQQEndBundleOverride();
    }
}

+ (void)updateQueryItemInfo:(id)queryItem type:(int)type shareDestType:(unsigned long long)shareDestType {
    NJQQBeginBundleOverride();
    @try {
        %orig;
    } @finally {
        NJQQEndBundleOverride();
    }
    NJQQFixQueryItem(queryItem);
}

+ (id)urlWithQueryItem:(id)queryItem type:(int)type shareDestType:(unsigned long long)shareDestType {
    id result = nil;
    NJQQBeginBundleOverride();
    @try {
        result = %orig;
    } @finally {
        NJQQEndBundleOverride();
    }
    NJQQFixQueryItem(queryItem);
    return NJQQFixURLValue(result);
}

+ (id)urlWithMessage:(id)message {
    id result = nil;
    NJQQBeginBundleOverride();
    @try {
        result = %orig;
    } @finally {
        NJQQEndBundleOverride();
    }
    return NJQQFixURLValue(result);
}

%end

%hook QQApiInterface

+ (long long)sendReq:(id)req {
    NJQQBeginBundleOverride();
    @try {
        return %orig;
    } @finally {
        NJQQEndBundleOverride();
    }
}

+ (long long)sendMessageToQQWithReq:(id)req {
    NJQQBeginBundleOverride();
    @try {
        return %orig;
    } @finally {
        NJQQEndBundleOverride();
    }
}

+ (long long)sendMessageToQQQZoneWithReq:(id)req {
    NJQQBeginBundleOverride();
    @try {
        return %orig;
    } @finally {
        NJQQEndBundleOverride();
    }
}

+ (NSString *)serializeURL:(NSString *)baseURL params:(NSDictionary *)params {
    NSMutableDictionary *fixedParams = [params mutableCopy] ?: [NSMutableDictionary dictionary];
    for (id key in [fixedParams allKeys]) {
        NSString *keyString = [key isKindOfClass:[NSString class]] ? (NSString *)key : @"";
        if ([keyString.lowercaseString containsString:@"bundle"]) {
            fixedParams[key] = NJBilibiliOfficialBundleID;
        }
    }
    NSString *result = nil;
    NJQQBeginBundleOverride();
    @try {
        result = %orig(baseURL, fixedParams);
    } @finally {
        NJQQEndBundleOverride();
    }
    id fixedValue = NJQQFixURLValue(result);
    return [fixedValue isKindOfClass:[NSString class]] ? fixedValue : result;
}

%end

#pragma mark - 我的页面大积分图标

/// 用 SF Symbols 生成与「我的服务」风格一致的粉色图标
static UIImage *NJBigPointIconNamed(NSString *symbolName) {
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config =
            [UIImageSymbolConfiguration configurationWithPointSize:24.0
                                                             weight:UIImageSymbolWeightRegular];
        UIImage *image = [UIImage systemImageNamed:symbolName withConfiguration:config];
        UIColor *pink = [UIColor colorWithRed:251.0 / 255.0
                                        green:114.0 / 255.0
                                         blue:153.0 / 255.0
                                        alpha:1.0];
        return [image imageWithTintColor:pink renderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    return nil;
}

/// 递归找出 Cell 中面积最大的 UIImageView（即主图标，排除角标 / 箭头）
static UIImageView *NJFindMainIconView(UIView *view) {
    UIImageView *bestView = nil;
    CGFloat bestArea = 0.0;
    NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:view];
    while (stack.count > 0) {
        UIView *current = stack.lastObject;
        [stack removeLastObject];
        for (UIView *subview in current.subviews) {
            if ([subview isKindOfClass:[UIImageView class]]) {
                CGFloat area = CGRectGetWidth(subview.bounds) * CGRectGetHeight(subview.bounds);
                if (area > bestArea) {
                    bestArea = area;
                    bestView = (UIImageView *)subview;
                }
            }
            [stack addObject:subview];
        }
    }
    return bestView;
}

/// 缓存大积分图标，用于在 Cell 布局时重新应用（避免被网络图片覆盖 / 隐藏）
static char NJBigPointIconAssociationKey;

static void NJReapplyBigPointIcon(UIView *cell) {
    UIImage *icon = objc_getAssociatedObject(cell, &NJBigPointIconAssociationKey);
    if (![icon isKindOfClass:[UIImage class]]) {
        return;
    }
    UIImageView *iconView = nil;
    @try {
        id value = [cell valueForKey:@"iconImgView"];
        if ([value isKindOfClass:[UIImageView class]]) {
            iconView = (UIImageView *)value;
        }
    } @catch (__unused NSException *exception) {
    }
    if (!iconView) {
        iconView = NJFindMainIconView(cell);
    }
    if (!iconView) {
        return;
    }
    iconView.hidden = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.image = icon;
}

/// 为「大积分签到 / 大积分中心」设置合适图标
static void NJApplyBigPointIconToCell(UIView *cell, id model) {
    NSString *title = nil;
    @try {
        id value = [model valueForKey:@"title"];
        if ([value isKindOfClass:[NSString class]]) {
            title = (NSString *)value;
        }
    } @catch (__unused NSException *exception) {
    }
    if (title.length == 0 || ![title containsString:@"大积分"]) {
        objc_setAssociatedObject(cell, &NJBigPointIconAssociationKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }
    BOOL isSign = [title containsString:@"签到"];
    UIImage *icon = NJBigPointIconNamed(isSign ? @"calendar.badge.checkmark" : @"star.circle");
    if (!icon) {
        return;
    }
    objc_setAssociatedObject(cell, &NJBigPointIconAssociationKey, icon,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NJReapplyBigPointIcon(cell);
}

// 「我的」服务格子：绘制图标后替换为大积分专属图标
%hook BBPhoneMineGridCell

- (void)drawIconAndMngWithModel:(id)model {
    %orig;
    NJApplyBigPointIconToCell(self, model);
}

- (void)layoutSubviews {
    %orig;
    NJReapplyBigPointIcon(self);
}

%end

%hook BBPhoneMineEnterCell

- (void)drawIconAndMngWithModel:(id)model {
    %orig;
    NJApplyBigPointIconToCell(self, model);
}

- (void)layoutSubviews {
    %orig;
    NJReapplyBigPointIcon(self);
}

%end

%hook BBPhoneMineItemCell

- (void)drawIconAndMngWithModel:(id)model {
    %orig;
    NJApplyBigPointIconToCell(self, model);
}

- (void)layoutSubviews {
    %orig;
    NJReapplyBigPointIcon(self);
}

%end

// 在「我的」页面的硬币 Label 旁边显示大积分数额
%hook BBPhoneMineInfoArea

- (void)configCoinLabel:(id)label {
    %orig;
    NJApplyBigPointToMineArea(self);
}

- (void)layoutSubviews {
    %orig;
    [NJApiRequest layoutBigPointLabelInArea:(UIView *)self];
}

- (void)setUserInfo:(id)userInfo {
    %orig;
    NJApplyBigPointToMineArea(self);
}

- (void)fillContentWith:(id)content {
    %orig;
    NJApplyBigPointToMineArea(self);
}

%end

// 「我的」页面「大积分签到」入口：点击后直接签到，不跳转
%hook BBPhoneUserCenterVC

- (void)viewDidLoad {
    %orig;
    // 登录态较晚就绪时，打开「我的」页面也会补执行自动签到等启动任务
    [NJApiRequest runLaunchTasks];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if (NJViewContainsLabelText(cell, @"大积分签到")) {
        __weak typeof(self) weakSelf = self;
        [NJApiRequest signBigPointWithCompletionHandler:^(BOOL success, NSString *message) {
            // 今日已签到时静默处理，不再弹窗
            if (success && [message containsString:@"已签到"]) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:(success ? @"大积分签到成功" : @"大积分签到失败")
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
                [(UIViewController *)weakSelf presentViewController:alert animated:YES completion:nil];
            });
        }];
        return;
    }
    %orig;
}

%end

%end

%ctor {
    if (NJ_MASTER_SWITCH_VALUE) {
        %init(App,BBPegasusViewController = objc_getClass("BBPegasusSwift.BBPegasusViewController"));
        // 兜底：首页视图未触发时，启动后再执行启动任务（登录态未就绪会自动跳过）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [NJApiRequest runLaunchTasks];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [NJApiRequest runLaunchTasks];
        });
    }
}

