//
//  APPayloadHolder.m
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 23/07/14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import "APPayloadHolder.h"

@implementation APPayloadHolder

- (id)copyWithZone:(NSZone *)zone
{
    APPayloadHolder *holder = [[APPayloadHolder allocWithZone:zone] init];
    holder.ident = self.ident;
    holder.data = [self.data copyWithZone:zone];
    holder.token = [self.token copyWithZone:zone];
    
    return holder;
}

@end
