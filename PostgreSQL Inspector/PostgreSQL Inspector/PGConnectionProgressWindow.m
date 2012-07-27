//
//  ConnectionProgressWindow.m
//  Database Inspector
//
//  Created by Tamas Czinege on 25/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGConnectionProgressWindow.h"
#import "PGConnectionEntry.h"

@interface PGConnectionProgressWindow ()

@end

@implementation PGConnectionProgressWindow
@synthesize connectingTextField;
@synthesize progressIndicator;
@synthesize connectionEntry;

-(NSString *)windowNibName
{
    return @"PGConnectionProgressWindow";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [connectingTextField setStringValue:[[NSString alloc] initWithFormat:@"Connecting to %@...", [connectionEntry description]]];
    [progressIndicator startAnimation:self];
}

@end
