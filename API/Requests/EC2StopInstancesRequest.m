
#import "EC2StopInstancesRequest.h"


@implementation EC2StopInstancesRequest

- (BOOL)start:(NSString *)instanceId {
    // Hard-coded one instance per request
    NSMutableDictionary *requestParameters = [@{@"InstanceId.1": instanceId} mutableCopy];
    BOOL res = [self startRequestWithAction:@"StopInstances" parameters:requestParameters];
    [requestParameters release];
    return res;
}

- (EC2StopInstancesResponse *)response {
    return (EC2StopInstancesResponse *) [super response];
}

- (AWSResponse *)parseResponse {
    return nil;
}

@end