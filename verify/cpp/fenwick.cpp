#include <atcoder/fenwicktree>
#include <cstdio>
using namespace atcoder;
int main() {
    int T; scanf("%d", &T);
    while (T--) {
        int n, q; scanf("%d %d", &n, &q);
        fenwick_tree<long long> ft(n);
        while (q--) {
            int op; scanf("%d", &op);
            if (op == 0) { int p; long long x; scanf("%d %lld", &p, &x); ft.add(p, x); }
            else { int l, r; scanf("%d %d", &l, &r); printf("%lld\n", ft.sum(l, r)); }
        }
    }
}
