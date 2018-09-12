//
//  APDeviceModel.h
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 21.02.14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface APDeviceModel : NSManagedObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *token;

@end
