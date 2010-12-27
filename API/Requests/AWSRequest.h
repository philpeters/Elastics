//
//  AWSRequest.h
//  Cloudwatch
//
//  Created by Dmitri Goutnik on 27/11/2010.
//  Copyright 2010 Tundra Bot. All rights reserved.
//

#import "AWSConstants.h"
#import "NSDate+StringConversions.h"
#import "AWSResponse.h"
#import "TBXML.h"

@protocol AWSRequestDelegate;

extern NSString *const kAWSAccessKeyIdOption;
extern NSString *const kAWSSecretAccessKeyOption;
extern NSString *const kAWSRegionOption;
extern NSString *const kAWSServiceOption;
extern NSString *const kAWSPathOption;
extern NSString *const kAWSUseSSLOption;

@interface AWSRequest : NSObject {
@private
	NSMutableDictionary		*_options;
	id<AWSRequestDelegate>	_delegate;
	NSConditionLock			*_connectionLock;
	NSMutableData			*_responseData;
	TBXML					*_responseXML;
	BOOL					_isRunning;
	NSDate					*_startedAt;
	NSDate					*_completedAt;
@protected
	AWSResponse				*_response;
}

+ (NSDictionary *)defaultOptions;
+ (void)setDefaultOptions:(NSDictionary *)options;

- (id)initWithOptions:(NSDictionary *)options delegate:(id<AWSRequestDelegate>)delegate;

@property (nonatomic, copy) NSString *accessKeyId;
@property (nonatomic, copy) NSString *secretAccessKey;
@property (nonatomic, copy) NSString *region;
@property (nonatomic, copy) NSString *service;
@property (nonatomic, copy) NSString *path;
@property (nonatomic) BOOL useSSL;

- (BOOL)start;
- (BOOL)startWithParameters:(NSDictionary *)parameters;

- (NSDate *)startedAt;
- (NSDate *)completedAt;

- (NSData *)responseData;
- (TBXML *)responseXML;
- (AWSResponse *)response;

// protected

- (NSDictionary *)_parameterListFromArray:(NSArray *)array key:(NSString *)key;
- (NSDictionary *)_filterListFromDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)_dimensionListFromDictionary:(NSDictionary *)dictionary;
- (BOOL)_startRequestWithAction:(NSString *)action parameters:(NSDictionary *)parameters;
- (void)_parseResponseData;

@end

@protocol AWSRequestDelegate

- (void)requestDidStartLoading:(AWSRequest *)request;
- (void)requestDidFinishLoading:(AWSRequest *)request;
- (void)request:(AWSRequest *)request didFailWithError:(NSError *)error;

@end