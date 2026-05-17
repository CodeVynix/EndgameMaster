void sf_init(void);
void sf_go(const char* fen);
void sf_stop(void);

int sf_eval(void);
int sf_depth(void);
int sf_nodes(void);
int sf_nps(void);

const char* sf_bestmove(void);
const char* sf_pv(void);
