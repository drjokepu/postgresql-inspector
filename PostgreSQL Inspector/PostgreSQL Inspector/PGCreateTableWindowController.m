//
//  PGCreateTableWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 04/02/2013.
//
//

#import "PGCreateTableWindowController.h"

@interface PGCreateTableWindowController ()

@end

@implementation PGCreateTableWindowController

-(NSString *)windowNibName
{
    return @"PGCreateTableWindowController";
}

-(void)windowDidLoad
{
    [super windowDidLoad];
}

-(void)didClickCancel:(id)sender
{
    [self close];
}

@end
