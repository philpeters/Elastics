#import "EC2Request.h"
#import "EC2RebootInstancesResponse.h"

@interface EC2RebootInstancesRequest : EC2Request

- (BOOL)start;

- (BOOL)start:(NSString *)instanceId;

- (EC2RebootInstancesResponse *)response;
@end