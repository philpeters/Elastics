//
//  EC2DescribeInstancesResponse.h
//  Elastics
//
//  Created by Dmitri Goutnik on 01/12/2010.
//  Copyright 2010 Tundra Bot. All rights reserved.
//

#import "EC2Response.h"

@interface EC2DescribeInstancesResponse : EC2Response {
@private
	NSArray		*_reservationSet;
	NSArray		*_instancesSet;			// collection of all instances in all reservations for convenience
}

@property (nonatomic, retain, readonly) NSArray *reservationSet;
@property (nonatomic, retain, readonly) NSArray *instancesSet;

@end
