//
//  APViewController.m
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 21.02.14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import "APViewController.h"
#import "APDeviceModel.h"

static NSString* const apServerProduction = @"gateway.push.apple.com";
static NSString* const apServerSandbox = @"gateway.sandbox.push.apple.com";

static NSString* const apPayloadPush = @"aps";
static NSString* const apPayloadSound = @"sound";
static NSString* const apPayloadText = @"alert";
static NSString* const apPayloadBadge = @"badge";

@interface APViewController ()
{
    NSData *_payload;
    NSString *_server;
    NSMutableArray *_certificates;
    NSArray *_allCertificates;
    
    NSMutableArray *_logs;
    
    NSMutableDictionary *_aps;
    NSMutableDictionary *_custom;
}

@end

@implementation APViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
        return nil;
    
    _server = apServerSandbox;
    _aps = [NSMutableDictionary dictionary];
    _custom = [NSMutableDictionary dictionary];
    _certificates = [NSMutableArray array];
    _logs = [NSMutableArray array];
    
    [[APNetworkManager sharedManager] setServerURL:_server];
    [[APNetworkManager sharedManager] setDelegate:self];

    return self;
}

- (void)preparePopUpButton
{
    NSArray *certs = [APHelper keychainCertificates];
    
    if (!certs.count)
        NSLog(@"No push certificates in keychain.");
    
    certs = [certs sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        APCertificateHolder *firstCert = a;
        APCertificateHolder *secondCert = b;

        BOOL adev = [APHelper isSandboxCertificate:firstCert];
        BOOL bdev = [APHelper isSandboxCertificate:secondCert];
        if (adev != bdev) {
            return adev ? NSOrderedAscending : NSOrderedDescending;
        }
        NSString *aname = [APHelper identifierForCertificate:firstCert];
        NSString *bname = [APHelper identifierForCertificate:secondCert];

        return [aname compare:bname];
    }];
    
    _allCertificates = certs;

    [self fillPopUpButton];
}

- (void)fillPopUpButton
{
    [self.windowCertificatePopUp removeAllItems];
    [self.windowCertificatePopUp addItemWithTitle:@"Select Push Certificate"];
    
    [_certificates removeAllObjects];
    
    for (APCertificateHolder *cert in _allCertificates) {
        BOOL sandbox = [APHelper isSandboxCertificate:cert];
        BOOL universal = [APHelper isUniversalCertificate:cert];
        BOOL production = [APHelper isProductionCertificate:cert];
        if (_server == apServerSandbox) {
            if (sandbox || universal) {
                NSString *name = [APHelper identifierForCertificate:cert];
                [self.windowCertificatePopUp addItemWithTitle:[NSString stringWithFormat:@"[%@] %@", (sandbox ? @"DEV" : @"UNI"), name]];
                
                [_certificates addObject:cert];
            }
        } else {
            if (production || universal) {
                NSString *name = [APHelper identifierForCertificate:cert];
                [self.windowCertificatePopUp addItemWithTitle:[NSString stringWithFormat:@"[%@] %@", (production ? @"PROD" : @"UNI"), name]];
                
                [_certificates addObject:cert];
            }
        }
    }
    
    [self.windowSendPushButton setEnabled:[self enableSendButton]];
}

#pragma mark -- Some local helpers
- (NSArray *)getSelectedDevicesTokens
{
    NSArray *devices = [self.windowArrayController selectedObjects];
    NSMutableArray *deviceTokens = [NSMutableArray array];
    for (APDeviceModel *device in devices) {
        [deviceTokens addObject:[APHelper deviceTokenAsDataFromString:device.token]];
    }
    
    return deviceTokens;
}

- (NSUInteger)getSelectedDevicesCount
{
    return [[self.windowArrayController selectedObjects] count];
}

- (BOOL)enableSendButton
{
    if (self.windowCertificatePopUp.indexOfSelectedItem == 0) {
        return NO;
    }

    if (self.windowDevicesList.numberOfSelectedRows == 0) {
        return NO;
    }
    
    if ([self.windowJSONLength.textColor isEqualTo:[NSColor redColor]]) {
        return NO;
    }
    
    return YES;
}

- (void)updatePreview
{
    static NSInteger oldBadge = NSIntegerMax;
    static NSUInteger oldMessLen = NSUIntegerMax;
    static NSControlStateValue oldSound = NSMixedState;
    
    if (oldMessLen == self.windowPushMessage.stringValue.length &&
        oldBadge == self.windowBadgeCount.integerValue &&
        oldSound == self.windowCheckSound.state) {
        return;
    }
    
    oldMessLen = [self.windowPushMessage.stringValue length];
    oldBadge = self.windowBadgeCount.integerValue;
    
    if (oldMessLen > 0) {
        [_aps setObject:self.windowPushMessage.stringValue forKey:apPayloadText];
    } else {
        [_aps removeObjectForKey:apPayloadText];
    }
    
    if (oldBadge != 0) {
        [_aps setObject:self.windowBadgeCount.stringValue forKey:apPayloadBadge];
    } else {
        [_aps removeObjectForKey:apPayloadBadge];
    }
    
    if (self.windowCheckSound.state == NSOnState) {
        [_aps setObject:@"default" forKey:apPayloadSound];
    } else {
        [_aps removeObjectForKey:apPayloadSound];
    }
    
    NSMutableDictionary *prevDict = [NSMutableDictionary dictionary];
    [prevDict setObject:_aps forKey:@"aps"];
    [prevDict addEntriesFromDictionary:_custom];

    NSData *prettyData = [NSJSONSerialization dataWithJSONObject:prevDict options:NSJSONWritingPrettyPrinted error:nil];
    NSString *string = [[NSString alloc] initWithData:prettyData encoding:NSUTF8StringEncoding];
    [self.windowPreviewJSON setStringValue:string];
    
    NSError *error = nil;
    NSData *payloadData = [NSJSONSerialization dataWithJSONObject:prevDict options:0 error:&error];
    if (error) {
        [self.windowJSONLength setStringValue:@"Bad JSON"];
        [self.windowJSONLength setTextColor:[NSColor redColor]];
    } else {
        [self.windowJSONLength setIntegerValue:payloadData.length];
        if (payloadData.length > 2048) {
            [self.windowJSONLength setTextColor:[NSColor redColor]];
            return;
        } else {
            [self.windowJSONLength setTextColor:[NSColor blueColor]];
            
            _payload = payloadData;
            
            [self.windowSendPushButton setEnabled:[self enableSendButton]];
        }
    }
}

- (void)addLogString:(NSString *)logString
{
    if ([_logs count] > 50) {
        [_logs removeObjectAtIndex:0];
    }
    
    [_logs addObject:logString];
    
    NSString *bigStr = [_logs componentsJoinedByString:@"\n"];
    NSRange strEnd = NSMakeRange(bigStr.length, 0);
    
    [self.windowShowLogs setString:bigStr];
    [self.windowShowLogs scrollRangeToVisible:strEnd];
}

#pragma mark -- XIB actions references
- (IBAction)actionSelectServer:(NSMatrix *)sender
{
    if (sender.selectedRow == 0 && _server != apServerProduction) {
        _server = apServerProduction;
    } else if (sender.selectedRow == 1 &&_server != apServerSandbox) {
        _server = apServerSandbox;
    } else {
        return;
    }
    
    [[APNetworkManager sharedManager] setServerURL:_server];
    
    [self fillPopUpButton];
}

- (IBAction)actionOpenCertificate:(NSPopUpButton *)sender
{
    if (sender.indexOfSelectedItem > 0) {
        APCertificateHolder *certificate = [_certificates objectAtIndex:sender.indexOfSelectedItem - 1];
        [[APNetworkManager sharedManager] setCertHolder:certificate];
        [[APNetworkManager sharedManager] connect];
    } else {
        [[APNetworkManager sharedManager] disconnect];
    }
    
    [self.windowSendPushButton setEnabled:[self enableSendButton]];
}

- (IBAction)actionCheckSound:(NSButton *)sender {
    [self updatePreview];
}

- (IBAction)actionPushSend:(NSButton *)sender
{
    if ([self getSelectedDevicesCount] == 0)
        return;
    
    [sender setEnabled:NO];
    [[APNetworkManager sharedManager] sendPush:_payload
                                     withCount:MAX(1, self.windowPushesCount.integerValue)
                           forDeviceWithTokens:[self getSelectedDevicesTokens]];
}

#pragma mark -- Delegate related functions
- (void)tableViewSelectionDidChange:(NSNotification *)notification;
{
    [self.windowSendPushButton setEnabled:[self enableSendButton]];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    NSTextField *object = [obj object];
    if (!object)
        return;
}

- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector
{
    NSTextField *field = (NSTextField *)control;
    
    if ([field.superview isKindOfClass:[NSClipView class]])
        return NO;
    
    if (commandSelector == @selector(insertNewline:)) {
        // new line action:
        // always insert a line-break character and don’t cause the receiver to end editing
        [textView insertNewlineIgnoringFieldEditor:self];
        return YES;
    } else if (commandSelector == @selector(insertTab:)) {
        // tab action:
        // always insert a tab character and don’t cause the receiver to end editing
        [textView insertTabIgnoringFieldEditor:self];
        return YES;
    }

    return NO;
}

#pragma mark -- Network manager callbacks
- (void)logString:(NSString *)logStr
{
    [self.windowConnectingIndicator stopAnimation:nil];
    [self.windowSendPushButton setEnabled:[self enableSendButton]];
    [self addLogString:logStr];
}

@end
