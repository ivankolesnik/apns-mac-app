//
//  APPayloadStack.h
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 23/07/14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import <Foundation/Foundation.h>

@class APPayloadHolder;
@interface APPayloadStack : NSObject

- (void)addPayload:(NSData *)payload withIdent:(NSUInteger)ident andToken:(NSData *)token;
- (BOOL)hasIdent:(NSUInteger)ident;
- (APPayloadHolder *)getNextPayload;
- (void)cleanupStack;

@end
