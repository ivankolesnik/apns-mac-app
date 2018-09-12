//
//  APPayloadHolder.h
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 23/07/14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APPayloadHolder : NSObject <NSCopying>

@property (nonatomic, strong) NSData *token;
@property (nonatomic, assign) NSUInteger ident;
@property (nonatomic, strong) NSData *data;

@end
