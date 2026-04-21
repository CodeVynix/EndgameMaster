#pragma once
#include <string>

namespace Stockfish {

    void init();

    void set_position(const std::string& fen);

    std::string search_best_move(int depth);

}