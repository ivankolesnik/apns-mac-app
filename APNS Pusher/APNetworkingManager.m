//
//  APNetworkingManager.m
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 01.05.14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import "APNetworkingManager.h"
#import "GCDAsyncSocket.h"
#import "APStackOfStacks.h"
#import "APPayloadHolder.h"

#define onebyte sizeof(uint8_t)
#define twobytes sizeof(uint16_t)
#define fourbytes sizeof(uint32_t)

#define swap_8(X) (uint8_t)X
#define swap_16(X) htons((uint16_t)X)
#define swap_32(X) htonl((uint32_t)X)

static APNetworkManager *volatile manager = nil;

const NSTimeInterval readDelay = 0.5;

@interface APNetworkManager () <GCDAsyncSocketDelegate>
{
    GCDAsyncSocket *_socket;
    BOOL _ready;
    
    APStackOfStacks *_payloadStack;
    dispatch_queue_t _backgroundQueue;
}

@end

@implementation APNetworkManager

+ (instancetype)sharedManager
{
    if (!manager) {
        @synchronized(self) {
            if (!manager) {
                manager = [self new];
            }
        }
    }

    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;
    
    _backgroundQueue = dispatch_queue_create("APNSNetworkManager", DISPATCH_QUEUE_SERIAL);
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_backgroundQueue];
    _payloadStack = [APStackOfStacks new];
    
    return self;
}

- (void)setCertHolder:(APCertificateHolder *)certificate
{
    dispatch_sync(_backgroundQueue, ^{
        [self doDisconnect];
        
        self->_certHolder = [certificate copy];
    });
}

- (void)connect
{
    dispatch_async(_backgroundQueue, ^{
        if (self->_socket.isDisconnected) {
            [self->_payloadStack clearAll];
            [self doConnect];
        }
    });
}

- (void)doConnect
{
    [self logString:[NSString stringWithFormat:@"Socket says: Connecting to \"%@\"...", _serverURL]];
    
    if (_socket.isDisconnected) {
        NSError *error = nil;
        [_socket connectToHost:_serverURL onPort:2195 error:&error];
        if (error) {
            NSString *logStr = [NSString stringWithFormat:@"Socket says: %@!",error.localizedDescription];
            [self logString:logStr];
        } else {
            if ([_payloadStack isEmpty]) {
                NSString *logStr = [NSString stringWithFormat:@"Socket says: Connected to \"%@\"!",_serverURL];
                [self logString:logStr];
            }
            
            [_socket startTLS:@{(NSString *)kCFStreamSSLCertificates:@[(id)_certHolder.identity],
                                (NSString *)kCFStreamSSLPeerName:_serverURL}];
        }
    }
}

- (void)disconnect
{
    [self logString:@"Socket says: Disconnecting..."];
    
    dispatch_async(_backgroundQueue, ^{
        [self doDisconnect];
    });
}

- (void)doDisconnect
{
    if (_socket.isConnected) {
        _ready = NO;
        [_socket disconnect];
        [_payloadStack clearAll];
    }
}

- (void)sendPush:(NSData *)payload withCount:(NSUInteger)count forDeviceWithTokens:(NSArray *)deviceTokens
{
    dispatch_async(_backgroundQueue, ^{
        if (self->_socket.isDisconnected) {
            [self->_payloadStack clearAll];
            [self doConnect];
        }
        
        [self writeData:payload withCount:count forDevices:deviceTokens];
    });
}

- (void)writeData:(NSData *)payload withCount:(NSUInteger)count forDevices:(NSArray *)devices
{
    [_payloadStack clearAll];
    
    uint32_t tag = 0;
    for (NSData *token in devices) {
        for (int i = 1; i <= count; i++) {
            @autoreleasepool {
                NSMutableData *data = [NSMutableData data];
                
                // Command part
                uint8_t command = 2;
                [data appendBytes:&command length:onebyte];
                
                NSMutableData *items = [NSMutableData data];
                // Device Token part
                uint8_t tokenId = 1;
                [items appendBytes:&tokenId length:onebyte];
                
                uint16_t tokenLength = swap_16(32);
                [items appendBytes:&tokenLength length:twobytes];
                
                [items appendData:token];
                
                // Payload part
                NSMutableDictionary *payDict = [NSJSONSerialization JSONObjectWithData:payload
                                                                               options:NSJSONReadingMutableContainers
                                                                                 error:nil];
                
                NSString *message = payDict[@"aps"][@"alert"];
                if (message) {
                    NSString *currTag = [NSString stringWithFormat:@" - %u",i];
                    message = [message stringByAppendingString:currTag];
                    payDict[@"aps"][@"alert"] = message;
                } else {
                    [payDict setObject:@(1) forKey:@"q"];
                }
                NSData *newPayload = [NSJSONSerialization dataWithJSONObject:payDict options:0 error:nil];
                
                uint8_t payloadId = 2;
                [items appendBytes:&payloadId length:onebyte];
                
                uint16_t payloadLength = swap_16([newPayload length]);
                [items appendBytes:&payloadLength length:twobytes];
                
                [items appendData:newPayload];
                
                // Notification id part
                uint8_t idId = 3;
                [items appendBytes:&idId length:onebyte];
                
                uint16_t idLength = swap_16(4);
                [items appendBytes:&idLength length:twobytes];
                
                uint32_t idItself = swap_32(tag);
                [items appendBytes:&idItself length:fourbytes];
                
                // Expiration part
                uint8_t expirationId = 4;
                [items appendBytes:&expirationId length:onebyte];
                
                uint16_t expirationLength = swap_16(4);
                [items appendBytes:&expirationLength length:twobytes];
                
                uint32_t expiry = swap_32(time(NULL)+86400); // 1 day
                [items appendBytes:&expiry length:fourbytes];
                
                // Priority part
                uint8_t priorityId = 5;
                [items appendBytes:&priorityId length:onebyte];
                
                uint16_t priorityLength = swap_16(1);
                [items appendBytes:&priorityLength length:twobytes];
                
                uint8_t priority = 10;
                [items appendBytes:&priority length:onebyte];
                
                // Command part
                uint32_t commandLength = swap_32([items length]);
                [data appendBytes:&commandLength length:fourbytes];
                
                [data appendData:items];
                
                [_payloadStack addPayload:data withIdent:tag andToken:token];
                
                tag++;
            }
        }
    }
    
    [self startSending];
}

- (void)startSending
{
    if (_ready) {
        [self sendNextData];
    }
}

- (void)sendNextData
{
    APPayloadHolder *stack = [_payloadStack getCurrentPayload];
    if (stack) {
        [_socket readDataToLength:6 withTimeout:readDelay tag:0];
        [_socket writeData:stack.data withTimeout:-1 tag:stack.ident];
    }
}

#pragma mark -- GCDAsyncSocketDelegate
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    _ready = NO;
    
    if (![_payloadStack isEmpty] && ![_payloadStack isExausted]) {
        [self doConnect];
    } else {
        [self logString:@"Socket says: Disconnected!\n"];
    }
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    _ready = YES;
    [self startSending];
    
    if (![_payloadStack isFinished]) {
        NSString *logStr = [NSString stringWithFormat:@"Socket says: Socket to \"%@\" successfully secured!",_serverURL];
        [self logString:logStr];
    }
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
    if (_ready && ![_payloadStack isExausted]) {
        [self sendNextData];
        return readDelay;
    } else if ([_payloadStack isFinished]) {
        NSUInteger total = [_payloadStack totalTokens];
        NSUInteger malformed = [_payloadStack malformedTokens];
        
        NSString *logStr = [NSString stringWithFormat:@"Socket says: Sended pushes on %lu of %lu devices!",
                            total - malformed, total];
        
        [self logString:logStr];
    }
    return 0;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	uint8_t status;
    uint32_t identifier;
    [data getBytes:&status range:NSMakeRange(1, 1)];
    [data getBytes:&identifier range:NSMakeRange(2, 4)];
    identifier = swap_32(identifier);
    
    NSString *desc = @"";
    [_payloadStack removeStackWithId:identifier];
    
    // http://developer.apple.com/library/mac/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW1
    switch (status) {
        case 0:
            _ready = NO;
            desc = @"APNS returned: no errors encountered!";
            break;
        case 1:
            _ready = NO;
            desc = @"APNS returned: processing error!";
            break;
        case 2:
            _ready = NO;
            desc = @"APNS returned: missing device token!";
            break;
        case 3:
            _ready = NO;
            desc = @"APNS returned: missing topic!";
            break;
        case 4:
            _ready = NO;
            desc = @"APNS returned: missing payload!";
            break;
        case 5:
            _ready = NO;
            desc = @"APNS returned: invalid token size!";
            break;
        case 6:
            _ready = NO;
            desc = @"APNS returned: invalid topic size!";
            break;
        case 7:
            _ready = NO;
            desc = @"APNS returned: invalid payload size!";
            break;
        case 8:
            _ready = NO;
            desc = @"APNS returned: invalid token!";
            break;
        case 10:
            _ready = NO;
            desc = @"APNS returned: shutdown!";
            break;
        default:
            _ready = NO;
            desc = @"APNS returned: unknown error!";
            break;
    }
    
    if (desc.length > 0) [self logString:desc];
    
    if ([_payloadStack isFinished]) {
        NSUInteger total = [_payloadStack totalTokens];
        NSUInteger malformed = [_payloadStack malformedTokens];
        
        NSString *logStr = [NSString stringWithFormat:@"Socket says: Sended pushes on %lu of %lu devices!",
                            total - malformed, total];
        
        [self logString:logStr];
    }
}

#pragma mark -- Self delegate
- (void)logString:(NSString *)logStr
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_delegate != nil && [self->_delegate respondsToSelector:@selector(logString:)]) {
            [self->_delegate logString:logStr];
        }
    });
}

@end
