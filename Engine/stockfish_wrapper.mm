#import <Foundation/Foundation.h>

// Dummy bridge (we’ll improve later)

extern "C" {

const char* sf_best_move(const char* fen) {
    // TEMP: return fake move so app doesn't crash
    return "e2e4";
}

}