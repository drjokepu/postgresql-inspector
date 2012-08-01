//
//  PGError.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 08/01/2012.
//
//

#import <Foundation/Foundation.h>

@interface PGError : NSError

@property (nonatomic, strong) NSString *sqlErrorMessage;
@property (nonatomic, assign) NSUInteger errorPosition;

@end
