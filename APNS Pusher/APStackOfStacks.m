//
//  APStackOfStacks.m
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 01/08/14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import "APStackOfStacks.h"
#import "APPayloadStack.h"

@implementation APStackOfStacks
{
    NSMutableDictionary *_stacks;
    
    NSUInteger _malformedTokens;
    NSUInteger _totalTokens;
    NSUInteger _sendedTokens;
}

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;
    
    _stacks = [NSMutableDictionary dictionary];
    _malformedTokens = 0;
    _totalTokens = 0;
    _sendedTokens = 0;
    
    return self;
}

- (void)addPayload:(NSData *)payload withIdent:(NSUInteger)ident andToken:(NSData *)token
{
    APPayloadStack *stack = _stacks[token];
    if (!stack) {
        stack = [APPayloadStack new];
        [stack addPayload:payload withIdent:ident andToken:token];
        
        _stacks[token] = stack;
        _totalTokens++;
    } else {
        [stack addPayload:payload withIdent:ident andToken:token];
    }
}

- (void)removeStackWithId:(NSUInteger)ident
{
    [_stacks enumerateKeysAndObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSData *key, APPayloadStack *obj, BOOL *stop)  {
        if ([obj hasIdent:ident]) {
            [self->_stacks removeObjectForKey:key];
            self->_malformedTokens++;
            *stop = YES;
        }
    }];
}

- (APPayloadHolder *)getCurrentPayload
{
    NSData *firstKey = [[_stacks allKeys] firstObject];
    if (!firstKey) {
        return nil;
    }
    APPayloadStack *currentStack = _stacks[firstKey];
    APPayloadHolder *stack = [currentStack getNextPayload];
    if (!stack) {
        [_stacks removeObjectForKey:firstKey];
        _sendedTokens++;
        return [self getCurrentPayload];

    }
    return stack;
}

- (void)clearAll
{
    [_stacks removeAllObjects];
    _malformedTokens = 0;
    _totalTokens = 0;
    _sendedTokens = 0;
}

- (NSUInteger)malformedTokens
{
    return _malformedTokens;
}

- (NSUInteger)totalTokens
{
    return _totalTokens;
}

- (BOOL)isExausted
{
    return (_totalTokens > 0) && (_sendedTokens + _malformedTokens == _totalTokens);
}

- (BOOL)isFinished
{
    return (_totalTokens > 0) && ([_stacks count] == 0);
}

- (BOOL)isEmpty
{
	return _totalTokens == 0;
}

- (BOOL)isMalformed
{
	return _malformedTokens == 0;
}


@end
