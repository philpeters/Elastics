#import "EC2Request.h"
#import "EC2StartInstancesResponse.h"

@interface EC2StartInstancesRequest : EC2Request

- (BOOL)start;

- (BOOL)start:(NSString *)instanceId;

- (EC2StartInstancesResponse *)response;
@end