//
//  PGSQLToken.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 02/01/2013.
//
//

#import <Foundation/Foundation.h>
#import "parsing/parsing_data_types.h"

@interface PGSQLToken : NSObject
@property (nonatomic, assign) enum sql_ast_node_type nodeType;
@property (nonatomic, assign) NSUInteger start;
@property (nonatomic, assign) NSUInteger length;

-(enum sql_token_type)tokenType;

@end
