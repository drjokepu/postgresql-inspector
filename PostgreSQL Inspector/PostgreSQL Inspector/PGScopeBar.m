//
//  PGScopeBar.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 01/05/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGScopeBar.h"

@interface PGScopeBar()

@property (nonatomic, strong) NSGradient *gradient;
@property (nonatomic, strong) NSColor *borderColor;

@end

@implementation PGScopeBar
@synthesize gradient, borderColor;

- (void)drawRect:(NSRect)dirtyRect
{
    if (gradient == nil)
    {
        gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.733
                                                                                       green:0.733
                                                                                        blue:0.733
                                                                                       alpha:1.000]
                                                 endingColor:[NSColor colorWithCalibratedRed:0.859
                                                                                       green:0.855
                                                                                        blue:0.859
                                                                                       alpha:1.000]];
    }
    
    if (borderColor == nil)
    {
        borderColor = [NSColor colorWithCalibratedRed:0.333 green:0.333 blue:0.333 alpha:1.000];
    }
    
    [gradient drawInRect:[self bounds] angle:90];
    [borderColor set];
    NSRectFill(NSMakeRect(0, 0, [self bounds].size.width, 1));
}

@end
