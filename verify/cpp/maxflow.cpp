#include <atcoder/maxflow>
#include <cstdio>
using namespace atcoder;
using ll = long long;
int main() {
    int T; scanf("%d", &T);
    while (T--) {
        int n, m; scanf("%d %d", &n, &m);
        mf_graph<ll> g(n);
        while (m--) { int u, v; ll c; scanf("%d %d %lld", &u, &v, &c); g.add_edge(u, v, c); }
        printf("%lld\n", g.flow(0, n - 1));
        auto cut = g.min_cut(0);
        for (int i = 0; i < n; i++) putchar(cut[i] ? '1' : '0');
        printf("\n");
    }
}
