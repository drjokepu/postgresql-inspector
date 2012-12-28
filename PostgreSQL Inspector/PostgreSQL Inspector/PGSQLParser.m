//
//  PGSQLParser.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 27/12/2012.
//
//

#import "PGSQLParser.h"
#import "parsing/parsing.h"

@implementation PGSQLParser

+(void)parse:(NSString *)sql
{
    sql_parse([sql UTF8String]);
}

@end
