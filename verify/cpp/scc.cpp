#include <atcoder/scc>
#include <algorithm>
#include <cstdio>
using namespace atcoder;
int main() {
    int T; scanf("%d", &T);
    while (T--) {
        int n, m; scanf("%d %d", &n, &m);
        scc_graph g(n);
        while (m--) { int u, v; scanf("%d %d", &u, &v); g.add_edge(u, v); }
        auto cs = g.scc();
        printf("%zu\n", cs.size());
        for (auto& c : cs) {
            std::sort(c.begin(), c.end());   // 成分内は昇順に正規化(Julia 版の仕様に合わせる)
            printf("%zu", c.size());
            for (int v : c) printf(" %d", v);
            printf("\n");
        }
    }
}
