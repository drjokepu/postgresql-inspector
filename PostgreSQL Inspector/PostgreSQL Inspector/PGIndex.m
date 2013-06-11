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
    @autoreleasepool
    {
        NSString *columns = [self.columnNames componentsJoinedByString:@", "];
        NSMutableArray *attributes = [[NSMutableArray alloc] init];
        
        if (self.primary)
            [attributes addObject:@"primary key"];
        if (self.unique)
            [attributes addObject:@"unique"];
        if (self.clustered)
            [attributes addObject:@"clustered"];
        if (self.deferrable)
            [attributes addObject:@"deferrable"];
        if (self.deferred)
            [attributes addObject:@"deferred"];
        
        if ([attributes count] > 0)
        {
            return [NSString stringWithFormat:@"%@ (%@)", columns, [attributes componentsJoinedByString:@", "]];
        }
        else
        {
            return columns;
        }
    }
}

@end
