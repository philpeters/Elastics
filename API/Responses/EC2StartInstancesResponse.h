
#import "EC2Response.h"


@interface EC2StartInstancesResponse : EC2Response {
@private
    NSArray *_instancesSet;            // collection of all instances in all reservations for convenience
}

@property(nonatomic, retain, readonly) NSArray *instancesSet;

@end