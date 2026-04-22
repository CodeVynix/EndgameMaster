#import "stockfish_bridge.h"
#include <string>

// ⚠️ TEMP FAKE ENGINE (replace later with real Stockfish call)
const char* sf_best_move(const char* fen) {
    static std::string move = "e2e4"; // test move
    return move.c_str();
}