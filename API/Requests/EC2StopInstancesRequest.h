#import "EC2Request.h"
#import "EC2StopInstancesResponse.h"

@interface EC2StopInstancesRequest : EC2Request

- (BOOL)start;

- (BOOL)start:(NSString *)instanceId;

- (EC2StopInstancesResponse *)response;
@end