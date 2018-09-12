//
//  APHelperFunctions.m
//  APNS Pusher
//
//  Created by Ivan Kolesnik on 18.02.14.
//  Copyright (c) 2014 Ivan Kolesnik. All rights reserved.
//

#import "APHelper.h"

@implementation APHelper

static NSString * const APDevelopmentPrefix = @"Apple Development IOS Push Services: ";
static NSString * const APProductionPrefix = @"Apple Production IOS Push Services: ";
static NSString * const APUniversalPrefix = @"Apple Push Services: ";

#pragma mark -- Device token helpers
+ (NSData *)deviceTokenAsDataFromString:(NSString *)string
{
    string = [self deviceTokenWithSpacesFromString:string];
    
    NSMutableData *deviceTokenData = [NSMutableData data];
	unsigned value = 0;
	NSScanner *scanner = [NSScanner scannerWithString:string];
    
	while(![scanner isAtEnd]) {
		[scanner scanHexInt:&value];
		value = htonl(value);
		[deviceTokenData appendBytes:&value length:sizeof(value)];
	}
    
    return deviceTokenData;
}

+ (NSString *)deviceTokenWithSpacesFromString:(NSString *)string
{
    if (![string rangeOfString:@" "].length) {
        //put in spaces in device token
        NSMutableString* tempString =  [NSMutableString stringWithString:string];
        unsigned offset = 0;
        for (unsigned i = 0; i < tempString.length; i++)
        {
            if (i%8 == 0 && i != 0 && i+offset < tempString.length-1)
            {
                [tempString insertString:@" " atIndex:i+offset];
                offset++;
            }
        }
        return tempString;
    }
    
    return string;
}

#pragma mark -- Certificate utilities
+ (NSArray *)keychainCertificates
{
    NSDictionary *opts = @{(id)kSecClass:(id)kSecClassCertificate,
                           (id)kSecMatchLimit: (id)kSecMatchLimitAll};

    CFArrayRef results = NULL;
    
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)opts, (CFTypeRef *)&results);
    if (status != noErr) {
        return nil;
    }
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (CFIndex i = 0; i < CFArrayGetCount(results); i++) {
        APCertificateHolder *cert = [APCertificateHolder new];
        cert.certificate = (SecCertificateRef)CFArrayGetValueAtIndex(results, i);
        
        APCertificateType type = [self typeForCertificate:cert identifier:nil];
        if (type == APCertificateUnknown) {
            continue;
        }
        
        cert = [self identityWithCertificateRef:cert];
        if (!cert) {
            continue;
        }
        
        [result addObject:cert];
    }
    
//    if (results) CFRelease(results);
    return result;
}

+ (APCertificateType)typeForCertificate:(APCertificateHolder *)certificate identifier:(NSString **)identifier
{
    NSString *name = BRIDGE_TRANSFER(NSString *, SecCertificateCopySubjectSummary(certificate.certificate));
    
    if ([name hasPrefix:APDevelopmentPrefix]) {
        if (identifier) *identifier = [name substringFromIndex:APDevelopmentPrefix.length];
        return APCertificateSandbox;
    }
    if ([name hasPrefix:APProductionPrefix]) {
        if (identifier) *identifier = [name substringFromIndex:APProductionPrefix.length];
        return APCertificateProduction;
    }
    if ([name hasPrefix:APUniversalPrefix]) {
        if (identifier) *identifier = [name substringFromIndex:APUniversalPrefix.length];
        return APCertificateUniversal;
    }
    if (identifier) *identifier = name;
    
    return APCertificateUnknown;
}

+ (APCertificateHolder *)identityWithCertificateData:(NSData *)certificate
{
    SecCertificateRef c = SecCertificateCreateWithData(kCFAllocatorDefault, (CFDataRef)certificate);
    if (!c)
        return nil;

    APCertificateHolder *cert = [APCertificateHolder new];
    cert.certificate = c;
    
    if (c) CFRelease(c);
    
    return [self identityWithCertificateRef:cert];
}

+ (APCertificateHolder *)identityWithCertificateRef:(APCertificateHolder *)certificate
{
    SecKeychainRef keychain = nil;
    SecIdentityRef identity = nil;
    OSStatus status = SecKeychainCopyDefault(&keychain);
    if (status != noErr) {
        return nil;
    }
    status = SecIdentityCreateWithCertificate(keychain, certificate.certificate, &identity);
    if (status != noErr) {
        return nil;
    }

    certificate.identity = identity;
    
    return certificate;
}

+ (APCertificateHolder *)identityWithPKCS12Data:(NSData *)pkcs12 password:(NSString *)password
{
    if (!pkcs12.length) {
        return nil;
    }
    const void *keys[] = {kSecImportExportPassphrase};
    const void *passwd = BRIDGE_RETAIN(const void *, password);
    const void *values[] = {passwd};
    CFRelease(passwd);
    CFDictionaryRef options = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1, NULL, NULL);
    CFArrayRef items = CFArrayCreate(kCFAllocatorDefault, 0, 0, NULL);
    CFDataRef pkData = BRIDGE_RETAIN(CFDataRef, pkcs12);
    OSStatus status = SecPKCS12Import(pkData, options, &items);
    CFRelease(pkData);
    CFRelease(options);
    if (status != noErr) {
        CFRelease(items);
        return nil;
    }
    
    CFIndex count = CFArrayGetCount(items);
    if (!count) {
        CFRelease(items);
        return nil;
    }
    
    CFDictionaryRef dict = CFArrayGetValueAtIndex(items, 0);
    CFRelease(items);
    SecIdentityRef ident = (SecIdentityRef)CFDictionaryGetValue(dict, kSecImportItemIdentity);
    if (!ident) {
        return nil;
    }
    
    return [APCertificateHolder holderWithIdentity:ident];
}

+ (NSString *)identifierForCertificate:(APCertificateHolder *)certificate
{
    NSString *result = nil;
    [self typeForCertificate:certificate identifier:&result];
    return result;
}

+ (BOOL)isSandboxCertificate:(APCertificateHolder *)certificate
{
    return [self typeForCertificate:certificate identifier:nil] == APCertificateSandbox;
}

+ (BOOL)isProductionCertificate:(APCertificateHolder *)certificate
{
    return [self typeForCertificate:certificate identifier:nil] == APCertificateProduction;
}

+ (BOOL)isUniversalCertificate:(APCertificateHolder *)certificate
{
    return [self typeForCertificate:certificate identifier:nil] == APCertificateUniversal;
}


@end
