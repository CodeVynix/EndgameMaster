#import "stockfish_wrapper.h"

#include <thread>
#include <string>
#include <sstream>
#include <iostream>
#include <mutex>
#include <condition_variable>

// Stockfish includes
#include "uci.h"
#include "thread.h"
#include "position.h"
#include "search.h"
#include "misc.h"

static std::mutex mtx;
static std::condition_variable cv;
static std::string bestMove = "";
static bool ready = false;

static void engine_loop() {
    UCI::init(Options);

    std::string token;
    while (true) {
        std::getline(std::cin, token);
        UCI::loop();
    }
}

extern "C" {

void sf_initialize() {
    static bool initialized = false;
    if (initialized) return;

    initialized = true;

    std::thread(engine_loop).detach();
}

void sf_send_command(const char* command) {
    std::string cmd(command);

    std::cout << cmd << std::endl;
}

const char* sf_best_move(const char* fen) {
    sf_initialize();

    std::stringstream ss;
    ss << "position fen " << fen << "\n";
    ss << "go movetime 300\n";

    std::cout << ss.str() << std::endl;

    // TEMP fallback until we hook stdout parsing
    bestMove = "e2e4";

    return bestMove.c_str();
}

}
