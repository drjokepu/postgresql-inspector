//
//  PGProgressSheet.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 07/06/2013.
//
//

#import "PGProgressSheet.h"

@interface PGProgressSheet ()
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@end

@implementation PGProgressSheet
@synthesize progressIndicator;

-(NSString *)windowNibName
{
    return @"PGProgressSheet";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [progressIndicator startAnimation:self];
}

@end
