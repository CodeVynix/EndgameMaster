#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void sf_send_command(const char* command);
const char* sf_best_move(const char* fen);

#ifdef __cplusplus
}
#endif
