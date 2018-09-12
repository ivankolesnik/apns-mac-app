//
//  APNetworkingManager.h
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 01.05.14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APHelper.h"

@protocol APNetworkManagerDelegate <NSObject>

@optional
- (void)logString:(NSString *)logStr;
@end

@interface APNetworkManager : NSObject

+ (instancetype)sharedManager;

- (void)connect;
- (void)disconnect;

- (void)sendPush:(NSData *)payload withCount:(NSUInteger)count forDeviceWithTokens:(NSArray *)deviceTokens;

@property (nonatomic, weak) id<APNetworkManagerDelegate> delegate;
@property (nonatomic, strong) APCertificateHolder *certHolder;
@property (nonatomic, strong) NSString *serverURL;

@end
