//
//  PGSQLParser.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 27/12/2012.
//
//

#import <Foundation/Foundation.h>
#import "parsing/parsing_data_types.h"

@class PGSQLParsingResult;
@interface PGSQLParser : NSObject

+(PGSQLParsingResult*)parse:(NSString*)sql;

@end
