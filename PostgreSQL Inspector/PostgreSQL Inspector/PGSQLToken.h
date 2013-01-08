//
//  PGSQLToken.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 02/01/2013.
//
//

#import <Foundation/Foundation.h>
#import "parsing/sql_symbol.h"

@interface PGSQLToken : NSObject
@property (nonatomic, assign) enum sql_symbol_type nodeType;
@property (nonatomic, assign) NSUInteger start;
@property (nonatomic, assign) NSUInteger length;

-(enum sql_token_type)tokenType;

@end
