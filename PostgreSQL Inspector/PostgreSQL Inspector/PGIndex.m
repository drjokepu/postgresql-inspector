//
//  PGIndex.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 19/12/2012.
//
//

#import "PGIndex.h"

@implementation PGIndex

-(NSString *)indexUIDefinition
{
    return [NSString stringWithFormat:@"%lu", [self.columnNames count]];
}

@end
