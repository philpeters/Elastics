
#import "EC2StartInstancesRequest.h"


@implementation EC2StartInstancesRequest

- (BOOL)start:(NSString *)instanceId {
    // Hard-coded one instance per request
    NSMutableDictionary *requestParameters = [@{@"InstanceId.1": instanceId} mutableCopy];
    BOOL res = [self startRequestWithAction:@"StartInstances" parameters:requestParameters];
    [requestParameters release];
    return res;
}

- (EC2StartInstancesResponse *)response {
    return (EC2StartInstancesResponse *) [super response];
}

- (AWSResponse *)parseResponse {
    return nil;
}

@end