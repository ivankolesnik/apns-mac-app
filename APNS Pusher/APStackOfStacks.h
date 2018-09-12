//
//  APStackOfStacks.h
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 01/08/14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import <Foundation/Foundation.h>

@class APPayloadStack;
@class APPayloadHolder;
@interface APStackOfStacks : NSObject

- (void)addPayload:(NSData *)payload withIdent:(NSUInteger)ident andToken:(NSData *)token;
- (void)removeStackWithId:(NSUInteger)ident;
- (APPayloadHolder *)getCurrentPayload;
- (void)clearAll;
- (NSUInteger)malformedTokens;
- (NSUInteger)totalTokens;
- (BOOL)isExausted;
- (BOOL)isFinished;
- (BOOL)isEmpty;
- (BOOL)isMalformed;

@end
