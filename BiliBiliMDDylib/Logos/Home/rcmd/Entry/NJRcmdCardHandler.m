//
//  NJRcmdCardHandler.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2025/7/4.
//

#import "NJRcmdCardHandler.h"
#import "NJRcmdCardEntry.h"
#import "NJRcmdSmallCoverV2Entry.h"
#import "NJRcmdBannerV8Entry.h"
#import "NJRcmdCmV1Entry.h"
#import "NJRcmdCmV2Entry.h"
#import "NJRcmdCmDoubleV9Entry.h"
#import "NJRcmdBannerIPadV8Entry.h"
#import "NJRcmdCmDoubleV7Entry.h"
#import "NJRcmdSmallCoverV9Entry.h"

@interface NJRcmdCardHandler ()

/// 需要注册的类
@property (nonatomic, strong, readonly) NSArray<Class> *cardEntryClasses;
/// 数据处理项
@property (nonatomic, strong) NSMutableDictionary<NSString *, NJRcmdCardEntry*> *cardEntryDic;

@end

@implementation NJRcmdCardHandler

@synthesize cardEntryClasses = _cardEntryClasses;

#pragma mark - Life Cycle Methods

- (instancetype)init {
    self = [super init];
    if (self) {
        [self doInit];
    }
    return self;
}



#pragma mark - Do Init

- (void)doInit {
    self.cardEntryDic = [NSMutableDictionary dictionary];
    [self registerEntry];
}

- (void)registerEntry {
    for (Class entryClass in self.cardEntryClasses) {
        NJRcmdCardEntry *entry = [[entryClass alloc] init];
        NSString *cardType = entry.cardType;
        if (cardType.length == 0) {
            continue;
        }
        self.cardEntryDic[cardType] = entry;
    }
}

#pragma mark - Override Methods

#pragma mark - Public Methods

- (NSDictionary<NSString *, NJRcmdCardEntry*> *)entryDic {
    return [self.cardEntryDic copy];
}

- (NSDictionary *)handleCardData:(NSMutableDictionary *)cardData {
    NSString *cardType = cardData[@"card_type"];
    if (cardType.length == 0) {
        return cardData;
    }
    // 9.18 起新增 cm_single_v1、cm_single_v7、cm_single_v9 等广告卡片，
    // 所有以 cm_ 开头的卡片类型都属于商业推广卡片，直接过滤
    if ([cardType hasPrefix:@"cm_"]) {
        return nil;
    }
    // 横幅类卡片（含 9.18 新增 banner_v3）统一不展示
    if ([cardType hasPrefix:@"banner"]) {
        return nil;
    }
    if ([self isAdCard:cardData]) {
        return nil;
    }
    NJRcmdCardEntry *cardEntry = self.cardEntryDic[cardType];
    if (!cardEntry) {
        return cardData;
    }
    NSDictionary *dataHandled = [cardEntry handleData:cardData];
    return dataHandled;
}

#pragma mark - Private Methods

/// 判断卡片是否属于广告/会员购推广
- (BOOL)isAdCard:(NSDictionary *)cardData {
    // 带广告信息的卡片
    if (cardData[@"ad_info"]) {
        return YES;
    }

    NSString *cardType = cardData[@"card_type"];
    NSString *cardGoto = cardData[@"card_goto"];
    NSString *gotoType = cardData[@"goto"];
    NSString *uri = cardData[@"uri"];

    // 卡片类型/跳转类型为会员购
    if ([cardType containsString:@"mall"] ||
        [cardGoto containsString:@"mall"] ||
        [gotoType isEqualToString:@"ad"] ||
        [gotoType isEqualToString:@"mall"] ||
        [cardGoto isEqualToString:@"ad"]) {
        return YES;
    }

    // 广告回调字段（args.ad_cb）只出现在商业推广卡片中
    id args = cardData[@"args"];
    if ([args isKindOfClass:[NSDictionary class]] && args[@"ad_cb"]) {
        return YES;
    }

    // 会员购落地页
    if ([uri isKindOfClass:[NSString class]] && uri.length > 0) {
        if ([uri containsString:@"mall.bilibili.com"] ||
            [uri containsString:@"bilibili://mall"] ||
            [uri containsString:@"mall/home"]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Property Methods

- (NSArray<Class> *)cardEntryClasses {
    if (!_cardEntryClasses) {
        _cardEntryClasses = @[[NJRcmdSmallCoverV2Entry class],      //
                              [NJRcmdBannerV8Entry class],          // banner
                              [NJRcmdBannerIPadV8Entry class],      // iPad banner
                              [NJRcmdCmV1Entry class],              // 小卡片广告
                              [NJRcmdCmV2Entry class],              // 小卡片广告
                              [NJRcmdCmDoubleV9Entry class],        // 大卡片广告
                              [NJRcmdCmDoubleV7Entry class],        // 大卡片广告
                              [NJRcmdSmallCoverV9Entry class],      // 直播
        ];
    }
    return _cardEntryClasses;
}


@end
