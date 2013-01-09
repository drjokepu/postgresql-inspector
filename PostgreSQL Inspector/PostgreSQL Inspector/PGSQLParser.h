//
//  PGSQLParser.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 27/12/2012.
//
//

#import <Foundation/Foundation.h>

@class PGSQLParsingResult;
@interface PGSQLParser : NSObject

+(PGSQLParsingResult*)parse:(NSString *)sql cursorPosition:(NSUInteger)cursorPosition;

@end
