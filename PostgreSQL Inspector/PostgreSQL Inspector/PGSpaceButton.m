//
//  PGSpaceButton.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 19/02/2013.
//
//

#import "PGSpaceButton.h"

@implementation PGSpaceButton

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self configure];
    }
    
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self configure];
    }
    
    return self;
}


-(void)configure
{
    [[self cell] setHighlightsBy:NSNoCellMask];
    [[self cell] setShowsStateBy:NSNoCellMask];
    [self setTitle:@""];
    [self setBezelStyle:NSSmallSquareBezelStyle];
}

@end
