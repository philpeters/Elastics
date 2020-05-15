
#import "EC2Response.h"

@interface EC2RebootInstancesResponse : EC2Response {
@private
    BOOL *_return;                  // Is true if the request succeeds, and an error otherwise.
}

@end