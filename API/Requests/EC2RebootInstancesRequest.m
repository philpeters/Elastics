
#import "EC2RebootInstancesRequest.h"


@implementation EC2RebootInstancesRequest

- (BOOL)start:(NSString *)instanceId {
    // Hard-coded one instance per request
    NSMutableDictionary *requestParameters = [@{@"InstanceId.1": instanceId} mutableCopy];
    BOOL res = [self startRequestWithAction:@"RebootInstances" parameters:requestParameters];
    [requestParameters release];
    return res;
}

- (EC2RebootInstancesResponse *)response {
    return (EC2RebootInstancesResponse *) [super response];
}

- (AWSResponse *)parseResponse {
    return nil;
}

@end