//
//  PathConverter.h
//  PlaylistMediaSync
//
//  Created by David Kessler on 12/17/13.
//  Copyright (c) 2013 Kopsis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PathConverter : NSObject

+ (NSString *)createPosixFromHFS:(NSString *)aHFSPathString;
    
@end
