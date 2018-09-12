//
//  APAppDelegate.h
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 18.02.14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class APViewController;

@interface APAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

@property (weak, nonatomic) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) IBOutlet APViewController *masterViewController;

- (IBAction)saveAction:(id)sender;

@end
