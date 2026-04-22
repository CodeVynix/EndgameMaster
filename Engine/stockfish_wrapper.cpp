#include "stockfish_wrapper.h"
#include <string>

// ⚠️ Replace this with real Stockfish call later if needed
extern "C" const char* sf_best_move(const char* fen) {
    static std::string move = "e2e4"; // temporary fallback
    return move.c_str();
}