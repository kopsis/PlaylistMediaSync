//
//  PathConverter.m
//  PlaylistMediaSync
//
//  Created by David Kessler on 12/17/13.
//  Copyright (c) 2013 Kopsis. All rights reserved.
//

#import <CoreFoundation/CFURL.h>
#import "PathConverter.h"

@implementation PathConverter

+ (NSString *)createPosixFromHFS:(NSString *)aHFSPathString {
    CFURLRef myCFURL = NULL;
    CFStringRef myPathString = NULL;
    NSString *myNSString;
    
    myCFURL = CFURLCreateWithFileSystemPath(NULL, (__bridge CFStringRef)(aHFSPathString), kCFURLHFSPathStyle, FALSE);
    myPathString = CFURLCopyFileSystemPath(myCFURL, kCFURLPOSIXPathStyle);
    myNSString = [[NSString alloc] initWithString:(__bridge NSString *)(myPathString)];
    return myNSString;
}
    
@end
