//
//  PGSQLParser.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 27/12/2012.
//
//

#import <Foundation/Foundation.h>

@interface PGSQLParser : NSObject

+(void)parse:(NSString*)sql;

@end
