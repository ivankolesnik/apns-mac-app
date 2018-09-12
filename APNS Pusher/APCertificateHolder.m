//
//  APCertificateHolder.m
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 01.05.14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import "APCertificateHolder.h"

@implementation APCertificateHolder

+ (instancetype)holderWithCertificate:(SecCertificateRef)cert andIdentity:(SecIdentityRef)ident
{
    APCertificateHolder *holder = [APCertificateHolder new];
    [holder setCertificate:cert];
    [holder setIdentity:ident];
    
    return holder;
}

+ (instancetype)holderWithCertificate:(SecCertificateRef)cert
{
    return [APCertificateHolder holderWithCertificate:cert andIdentity:nil];
}

+ (instancetype)holderWithIdentity:(SecIdentityRef)ident
{
    return [APCertificateHolder holderWithCertificate:nil andIdentity:ident];
}

- (id)copyWithZone:(NSZone *)zone
{
    APCertificateHolder *newCert = [[APCertificateHolder allocWithZone:zone] init];
    
    [newCert setCertificate:self.certificate];
    [newCert setIdentity:self.identity];
    
    return newCert;
}

@end
