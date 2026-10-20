#include <atcoder/mincostflow>
#include <cstdio>
using namespace atcoder;
using ll = long long;
int main() {
    int T; scanf("%d", &T);
    while (T--) {
        int n, m; scanf("%d %d", &n, &m);
        mcf_graph<ll, ll> g(n);
        while (m--) { int u, v; ll c, w; scanf("%d %d %lld %lld", &u, &v, &c, &w); g.add_edge(u, v, c, w); }
        auto sl = g.slope(0, n - 1);
        printf("%zu\n", sl.size());
        for (auto& p : sl) printf("%lld %lld\n", p.first, p.second);
    }
}
