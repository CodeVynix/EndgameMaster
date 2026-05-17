#import "stockfish_wrapper.h"
#include <iostream>
#include <thread>
#include <sstream>

extern "C" {

static std::string lastBestMove = "e2e4";

// Fake minimal engine loop (replace later with real Stockfish integration)
void sf_send_command(const char* command) {
    std::string cmd(command);

    std::cout << "Received: " << cmd << std::endl;

    // VERY BASIC parsing (for now)
    if (cmd.find("position") != std::string::npos) {
        // pretend we processed position
    }

    if (cmd.find("go") != std::string::npos) {
        // simulate thinking
        std::this_thread::sleep_for(std::chrono::milliseconds(200));
        lastBestMove = "e7e5"; // temporary fake response
    }
}

const char* sf_best_move(const char* fen) {
    sf_send_command("ucinewgame");

    std::string pos = "position fen ";
    pos += fen;
    sf_send_command(pos.c_str());

    sf_send_command("go movetime 200");

    return lastBestMove.c_str();
}

}
