//
//  APViewController.h
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 21.02.14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "APNetworkManager.h"
#import "APNetworkingManager.h"
#import "APArrayController.h"

@interface APViewController : NSViewController <APNetworkManagerDelegate,
                                                NSTextFieldDelegate,
                                                NSTextViewDelegate,
                                                NSTableViewDelegate>

@property (strong, nonatomic) IBOutlet NSPopUpButton *windowCertificatePopUp;
@property (strong, nonatomic) IBOutlet NSTableView *windowDevicesList;
@property (strong, nonatomic) IBOutlet NSMatrix *windowServerSelector;

@property (strong, nonatomic) IBOutlet NSTextField *windowPushMessage;
@property (strong, nonatomic) IBOutlet NSButton *windowCheckSound;


@property (strong, nonatomic) IBOutlet NSTextField *windowJSONLength;
@property (strong, nonatomic) IBOutlet NSTextField *windowPreviewJSON;

@property (strong, nonatomic) IBOutlet NSProgressIndicator *windowConnectingIndicator;
@property (strong, nonatomic) IBOutlet NSButton *windowSendPushButton;

@property (strong, nonatomic) IBOutlet NSTextField *windowPushesCount;
@property (strong, nonatomic) IBOutlet NSTextView *windowShowLogs;
@property (strong, nonatomic) IBOutlet NSTextField *windowBadgeCount;

@property (strong, nonatomic) IBOutlet APArrayController *windowArrayController;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)actionOpenCertificate:(NSPopUpButton *)sender;
- (IBAction)actionSelectServer:(NSMatrix *)sender;
- (IBAction)actionCheckSound:(NSButton *)sender;
- (IBAction)actionPushSend:(NSButton *)sender;

- (void)preparePopUpButton;
- (void)updatePreview;


@end
