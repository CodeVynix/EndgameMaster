#import "StockfishWrapper.h"

// Include Stockfish headers
#include "stockfish.h"

@implementation StockfishWrapper

+ (instancetype)shared {
    static StockfishWrapper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[StockfishWrapper alloc] init];
    });
    return sharedInstance;
}

- (void)initializeEngine {
    Stockfish::init();
}

- (NSString *)getBestMove:(NSString *)fen {

    std::string fenStr = [fen UTF8String];

    // Setup position
    Stockfish::set_position(fenStr);

    // Run search
    std::string bestMove = Stockfish::search_best_move(12); // depth 12

    return [NSString stringWithUTF8String:bestMove.c_str()];
}

@end