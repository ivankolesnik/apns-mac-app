//
//  APPayloadStack.m
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 23/07/14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import "APPayloadStack.h"
#import "APPayloadHolder.h"

@implementation APPayloadStack
{
    NSMutableArray *_payloads;
    
    NSUInteger _position;
}

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;
    
    _payloads = [NSMutableArray array];
    _position = 0;
    
    return self;
}

- (void)addPayload:(NSData *)payload withIdent:(NSUInteger)ident andToken:(NSData *)token
{
    APPayloadHolder *holder = [APPayloadHolder new];
    holder.data = payload;
    holder.ident = ident;
    holder.token = token;
    
    [_payloads addObject:holder];
}

- (APPayloadHolder *)getNextPayload
{
    APPayloadHolder *holder = nil;
    if (_position < [_payloads count]) {
        holder = _payloads[_position];
        _position++;
    }
    return holder;
}

- (void)cleanupStack
{
    [_payloads removeAllObjects];
    _position = 0;
}

- (BOOL)hasIdent:(NSUInteger)ident
{
    BOOL hasIdent = NO;
    for (APPayloadHolder *holder in _payloads) {
        if (holder.ident == ident) {
            hasIdent = YES;
            break;
        }
    }
    return hasIdent;
}

@end
