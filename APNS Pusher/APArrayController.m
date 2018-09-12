//
//  APArrayController.m
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 24.02.14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import "APArrayController.h"

@implementation APArrayController

- (void)remove:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Do you really want to delete this device?"];
    [alert setInformativeText:@"Deleting a device cannot be undone."];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert setDelegate:self];
    //[alert respondsToSelector:@selector(doRemove)];
    [alert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)alertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
    if (returnCode == 1000) {
        // We want to remove the saved device
        [super remove:self];
        
        [self saveDevices];
    }
}

- (void)saveDevices {
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

@end
