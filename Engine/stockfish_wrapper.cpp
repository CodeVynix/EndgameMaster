#include <string>
#include <iostream>

extern "C" {

void sf_send_command(const char* command) {
    // TEMP: just print (to verify linking works)
    std::cout << "CMD: " << command << std::endl;
}

const char* sf_best_move(const char* fen) {
    // TEMP: dummy move
    return "e2e4";
}

}