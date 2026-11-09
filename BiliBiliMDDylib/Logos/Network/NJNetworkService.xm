// 网络层

#import <UIKit/UIKit.h>
#import "NJApiDataManger.h"
#import "NJCommonDefine.h"
#import "NSURL+NJPath.h"
#import "BFCAccountHTTPCookie.h"
#import "BFCApiOptions.h"
#import "BFCApiModelDescription.h"

@protocol BFCApiMetrics <NSObject>

@end


%group App

// 发送请求的最上层的类
%hook BFCApiRequest

- (void)requestAsync {
    %orig;
}

- (void)requestSync {
    %orig;
}

%end

// 发送请求的 NSOperation
%hook BFCApiRequestOperation

- (id)init {
    return %orig;
}

- (id)bfcRequest:(NSURLRequest *)request taskType:(unsigned long long)type completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error, id<BFCApiMetrics> metrics))handler {
    return %orig(request, type, handler);
}

%end

@interface BFCRequest : NSObject

@end

%hook BFCRequest

// 9.18 起 BFCRequest 的初始化方法去掉了 priority 参数，改为统一在
// handleFinishCallbackWithData:response:error: 中拦截响应数据，
// 这样可以保证所有通过 BFCRequest 发出的请求都能被过滤。
- (void)handleFinishCallbackWithData:(NSData *)data
                            response:(NSURLResponse *)response
                               error:(NSError *)error {
    data = [[NJApiDataManger sharedInstance] handleWithData:data
                                                   response:response
                                                      error:error];
    %orig(data, response, error);
}

%end

// 9.18 新版首页（BBPegasusSwift）使用 Swift 原生 URLSession 请求，
// 不经过 BFCRequest，这里在 completionHandler 层兜底过滤广告数据。
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    if (!completionHandler) {
        return %orig;
    }
    void (^wrappedHandler)(NSData *, NSURLResponse *, NSError *) =
    ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSData *filteredData = [[NJApiDataManger sharedInstance] handleWithData:data
                                                                      response:response
                                                                         error:error];
        completionHandler(filteredData, response, error);
    };
    return %orig(request, wrappedHandler);
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url
                        completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    if (!completionHandler) {
        return %orig;
    }
    void (^wrappedHandler)(NSData *, NSURLResponse *, NSError *) =
    ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSData *filteredData = [[NJApiDataManger sharedInstance] handleWithData:data
                                                                      response:response
                                                                         error:error];
        completionHandler(filteredData, response, error);
    };
    return %orig(url, wrappedHandler);
}

%end

%hook BFCApiOptions

- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
    
    [desc appendFormat:@"<%@: %p>\n", NSStringFromClass([self class]), self];
    
    [desc appendFormat:@"baseUrl: %@\n", self.baseUrl];
    [desc appendFormat:@"localPath: %@\n", self.localPath];
    [desc appendFormat:@"localData: %@\n", self.localData];
    [desc appendFormat:@"modelDescriptions: %@\n", self.modelDescriptions];
    [desc appendFormat:@"params: %@\n", self.params];
    [desc appendFormat:@"extraHTTPHeader: %@\n", self.extraHTTPHeader];
    
    [desc appendFormat:@"requestMethod: %llu\n", self.requestMethod];
    [desc appendFormat:@"signType: %llu\n", self.signType];
    [desc appendFormat:@"taskType: %llu\n", self.taskType];
    [desc appendFormat:@"timeoutInterval: %f\n", self.timeoutInterval];
    [desc appendFormat:@"cacheValidLife: %f\n", self.cacheValidLife];
    
    [desc appendFormat:@"ignoreCache: %@\n", self.ignoreCache ? @"YES" : @"NO"];
    [desc appendFormat:@"enableHttpCache: %@\n", self.enableHttpCache ? @"YES" : @"NO"];
    [desc appendFormat:@"disableDefaultErrorMessage: %@\n", self.disableDefaultErrorMessage ? @"YES" : @"NO"];
    [desc appendFormat:@"enableDeviceNameParam: %@\n", self.enableDeviceNameParam ? @"YES" : @"NO"];
    [desc appendFormat:@"ignoreCodeNonZero: %@\n", self.ignoreCodeNonZero ? @"YES" : @"NO"];
    
    [desc appendFormat:@"apiKeySecretType: %llu\n", self.apiKeySecretType];
    [desc appendFormat:@"taskDescription: %@\n", self.taskDescription];
    
    return desc;
}

%end

%hook BFCAccountHTTPCookie

- (NSString *)description {
    NSString *orig = %orig;
    NSString *ret = [orig stringByAppendingFormat:@"name:%@,value:%@,httpOnly:%@", self.name, self.value, @(self.httpOnly)];
    return ret;
}

%end

%hook BFCApiModelDescription

- (NSString *)description {
    NSString *orig = %orig;
    NSString *ret = [orig stringByAppendingFormat:@"keyPath:%@,isArray:%@,mappingClass:%@,isOptional:%@", self.keyPath, @(self.isArray), self.mappingClass, @(self.isOptional)];
    return ret;
}

%end

%end

%ctor {
    if (NJ_MASTER_SWITCH_VALUE) {
        %init(App);
    }
}
