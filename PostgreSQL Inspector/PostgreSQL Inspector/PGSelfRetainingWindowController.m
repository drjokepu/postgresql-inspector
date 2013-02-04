//
//  PGSelfRetainingWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 04/02/2013.
//
//

#import "PGSelfRetainingWindowController.h"

static NSMutableArray *windowList = nil;

@implementation PGSelfRetainingWindowController

+(void)initialize
{
    windowList = [[NSMutableArray alloc] init];
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    [windowList addObject:self];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [windowList removeObject:self];
}

@end
