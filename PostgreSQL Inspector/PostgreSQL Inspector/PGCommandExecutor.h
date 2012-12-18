//
//  PGCommandExecutor.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/12/2012.
//
//

#import <Foundation/Foundation.h>

@class PGCommand, PGResult;

@interface PGCommandExecutor : NSObject

@property (nonatomic, weak) PGCommand *command;
@property (nonatomic, assign) BOOL rowByRow;
@property (nonatomic, strong) void (^onTuplesOk)(PGResult *result);
@property (nonatomic, strong) void (^onNoMoreResults)(void);

-(id)initWithCommand:(PGCommand*)theCommand;
-(void)execute;

@end
