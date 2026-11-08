//
//  NJSettingSkullViewModel.h
//  BiliBiliTweak
//
//  Created by touchWorld on 2025/8/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NJSettingSkullViewModel : NSObject

/// 业务id
@property (nonatomic, copy) NSString *bizId;
/// cell重利用Id
@property (nonatomic, copy) NSString *cellId;
/// 标题
@property (nonatomic, copy) NSString *title;
/// 副标题
@property (nonatomic, copy) NSString *subTitle;
/// 副标题颜色（不设置则使用默认颜色）
@property (nonatomic, strong) UIColor *subTitleColor;
/// 图标（SF Symbols 名称）
@property (nonatomic, copy) NSString *iconName;


- (instancetype)initWithBizId:(NSString *)bizId
                       cellId:(NSString *)cellId
                        title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
