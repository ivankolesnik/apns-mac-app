//
//  APHelperFunctions.h
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 18.02.14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APCertificateHolder.h"

#define BRIDGE(class, value)            (__bridge class)(value)
#define BRIDGE_RETAIN(class, value)     (class)CFBridgingRetain(value)
#define BRIDGE_TRANSFER(class, value)   (class)CFBridgingRelease(value)

typedef enum {
    APCertificateSandbox = 1,
    APCertificateProduction,
    APCertificateUniversal,
    APCertificateUnknown = 0,
} APCertificateType;

@interface APHelper : NSObject

+ (NSData *)deviceTokenAsDataFromString:(NSString *)string;
+ (NSString *)deviceTokenWithSpacesFromString:(NSString *)string;

+ (NSArray<APCertificateHolder *> *)keychainCertificates;
+ (APCertificateType)typeForCertificate:(APCertificateHolder *)certificate identifier:(NSString **)identifier;
+ (APCertificateHolder *)identityWithCertificateData:(NSData *)certificate;
+ (APCertificateHolder *)identityWithCertificateRef:(APCertificateHolder *)certificate;
+ (APCertificateHolder *)identityWithPKCS12Data:(NSData *)pkcs12 password:(NSString *)password;

+ (NSString *)identifierForCertificate:(APCertificateHolder *)certificate;
+ (BOOL)isSandboxCertificate:(APCertificateHolder *)certificate;
+ (BOOL)isProductionCertificate:(APCertificateHolder *)certificate;
+ (BOOL)isUniversalCertificate:(APCertificateHolder *)certificate;

@end
