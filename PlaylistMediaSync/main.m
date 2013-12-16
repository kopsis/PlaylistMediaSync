//
//  main.m
//  PlaylistMediaSync
//
//  Created by David Kessler on 12/16/13.
//  Copyright (c) 2013 Kopsis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AppleScriptObjC/AppleScriptObjC.h>

int main(int argc, const char * argv[])
{
    [[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];
    return NSApplicationMain(argc, argv);
}
