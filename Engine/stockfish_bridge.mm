#import <Foundation/Foundation.h>
#include <stdio.h>
#include <string>
#include <thread>
#include <atomic>

using namespace std;

static FILE* engine = nullptr;
static atomic<bool> running(false);

static string bestMove = "";
static int evalCp = 0;
static int depth = 0;
static int nodes = 0;
static int nps = 0;
static string pv = "";

void send(const string& cmd) {
    fprintf(engine, "%s\n", cmd.c_str());
    fflush(engine);
}

void readLoop() {
    char buffer[1024];
    
    while (running && fgets(buffer, sizeof(buffer), engine)) {
        string line(buffer);
        
        if (line.find("info depth") != string::npos) {
            
            if (line.find("depth") != string::npos) {
                depth = stoi(line.substr(line.find("depth") + 6));
            }
            
            if (line.find("nodes") != string::npos) {
                nodes = stoi(line.substr(line.find("nodes") + 6));
            }
            
            if (line.find("nps") != string::npos) {
                nps = stoi(line.substr(line.find("nps") + 4));
            }
            
            if (line.find("score cp") != string::npos) {
                evalCp = stoi(line.substr(line.find("score cp") + 9));
            }
            
            if (line.find("pv") != string::npos) {
                pv = line.substr(line.find("pv") + 3);
            }
        }
        
        if (line.find("bestmove") != string::npos) {
            bestMove = line.substr(line.find("bestmove") + 9, 5);
        }
    }
}

extern "C" {

void sf_init() {
    if (engine) return;
    
    engine = popen("./Stockfish/src/stockfish", "r+");
    running = true;
    
    send("uci");
    send("setoption name MultiPV value 3");
    
    thread(readLoop).detach();
}

void sf_go(const char* fen) {
    send("stop");
    send(string("position fen ") + fen);
    send("go infinite");
}

void sf_stop() {
    send("stop");
}

int sf_eval() { return evalCp; }
int sf_depth() { return depth; }
int sf_nodes() { return nodes; }
int sf_nps() { return nps; }

const char* sf_bestmove() { return bestMove.c_str(); }
const char* sf_pv() { return pv.c_str(); }

}
