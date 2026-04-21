#import <Foundation/Foundation.h>

@interface StockfishWrapper : NSObject

+ (instancetype)shared;

- (void)initializeEngine;
- (NSString *)getBestMove:(NSString *)fen;

@end