//
//  PGCommand.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/12/2012.
//
//

#import "PGCommand.h"
#import "PGConnection.h"
#import <libpq-fe.h>

@implementation PGCommand
@synthesize commandText;
@synthesize connection;

-(void)execAsync
{
    
}

@end


