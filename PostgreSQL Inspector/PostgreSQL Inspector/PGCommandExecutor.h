//
//  PGCommandExecutor.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/12/2012.
//
//

#import <Foundation/Foundation.h>

@class PGCommand;

@interface PGCommandExecutor : NSObject

@property (nonatomic, strong) PGCommand *command;
@property (nonatomic, assign) BOOL rowByRow;

-(void)execute;

@end
