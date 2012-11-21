//
//  AppDelegate.m
//  SleepUnmounter
//
//  Created by cirrus on 21/11/12.
//  Copyright (c) 2012 cirrus. All rights reserved.
//

#import "AppDelegate.h"
#import <IOKit/IOMessage.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <AppKit/AppKit.h>

@implementation AppDelegate

io_connect_t  root_port;
IONotificationPortRef notifyPortRef;
io_object_t notifierObject;

BOOL umount(NSString* mount_point)
{
    //Unmount and eject
    return [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:mount_point];
}

void umountAllDrives(void)
{
    NSLog(@"Unmounting removable...");
    //Using NSWorkspace to get the removableMedia list
    for (id mount in [[NSWorkspace sharedWorkspace] mountedRemovableMedia])
    {
        BOOL success = umount(mount);
        NSLog(@"Unmounting: \"%@\" was %s",mount, success?"successful":"not successful");
    }
}

void SleepCallBack( void * refCon, io_service_t service, natural_t messageType, void * messageArgument )
{
    //Power event received
    switch ( messageType )
    {
        case kIOMessageCanSystemSleep:
            NSLog(@"Received kIOMessageCanSystemSleep");
            IOAllowPowerChange( root_port, (long)messageArgument );
            break;
        case kIOMessageSystemWillSleep:
            NSLog(@"Received kIOMessageSystemWillSleep");
            umountAllDrives();
            IOAllowPowerChange( root_port, (long)messageArgument );
            break;
        /*case kIOMessageSystemWillPowerOn:
            NSLog(@"Received kIOMessageSystemWillPowerOn");
            //System has started the wake up process...
            break;
        case kIOMessageSystemHasPoweredOn:
            NSLog(@"Received kIOMessageSystemHasPoweredOn");
            //System has finished waking up...
            break;*/
        default:
            break;
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"Starting SleepUnmounter");
    void* refCon = nil;
    root_port = IORegisterForSystemPower( refCon, &notifyPortRef, SleepCallBack, &notifierObject );
    if ( root_port == 0 )
    {
        NSLog(@"IORegisterForSystemPower failed");
        [NSApp terminate:self];
    }
    CFRunLoopAddSource( CFRunLoopGetCurrent(),IONotificationPortGetRunLoopSource(notifyPortRef), kCFRunLoopCommonModes );
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    NSLog(@"SleepUnmounter is exiting...");
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(),IONotificationPortGetRunLoopSource(notifyPortRef),kCFRunLoopCommonModes);
    IODeregisterForSystemPower(&notifierObject);
    IOServiceClose(root_port);
    IONotificationPortDestroy(notifyPortRef );
}

@end
