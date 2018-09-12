//
//  APCertificateHolder.h
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 01.05.14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APCertificateHolder : NSObject <NSCopying>

+ (instancetype)holderWithCertificate:(SecCertificateRef)cert andIdentity:(SecIdentityRef)ident;
+ (instancetype)holderWithCertificate:(SecCertificateRef)cert;
+ (instancetype)holderWithIdentity:(SecIdentityRef)ident;

@property (nonatomic, assign) SecCertificateRef certificate;
@property (nonatomic, assign) SecIdentityRef identity;

@end
