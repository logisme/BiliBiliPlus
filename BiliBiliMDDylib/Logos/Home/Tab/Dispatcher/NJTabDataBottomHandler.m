//
//  NJTabDataBottomHandler.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2026/1/4.
//

#import "NJTabDataBottomHandler.h"
#import "NJCommonDefine.h"

@implementation NJTabDataBottomHandler

#pragma mark - Life Cycle Methods


#pragma mark - Override Methods

/// 业务类型
- (NSString *)bizType {
    return @"bottom";
}

/// 处理数据
/// - Parameter data: 要处理的数据
/// @return 处理后的数据
- (NSObject *)handleData:(NSObject *)data {
    if (![data isKindOfClass:[NSArray class]]) {
        return data;
    }
    NSArray *items = (NSArray *)data;
    NSMutableArray *newItems = [NSMutableArray array];
    for (NSMutableDictionary *itemDic in items) {
        NSDictionary *itemData = [self handleItemData:itemDic];
        if (itemData) {
            [newItems addObject:itemData];
        }
    }
    return [newItems copy];
}

#pragma mark - Private Methods

/// 处理版块数据
/// - Parameter tabData: 版块数据
- (NSDictionary *)handleItemData:(NSMutableDictionary *)tabData {
    NSString *tabId = tabData[@"tab_id"];
    NSString *uri = [tabData[@"uri"] isKindOfClass:[NSString class]] ? tabData[@"uri"] : nil;
    id typeValue = tabData[@"type"];
    NSInteger type = [typeValue respondsToSelector:@selector(integerValue)] ? [typeValue integerValue] : -1;

    // 发布（+号）
    BOOL isPublish = [tabId isEqualToString:@"publish"]
        || (uri.length > 0 && [uri containsString:@"uper/center_plus"])
        || type == 3;
    if (isPublish && !NJ_PUBLISH_VALUE) {
        return nil;
    }
    // 会员购
    BOOL isMall = [tabId isEqualToString:@"会员购Bottom"]
        || (uri.length > 0 && [uri containsString:@"mall/home"]);
    if (isMall && !NJ_MALL_VALUE) {
        return nil;
    }
    return tabData;
}

@end
