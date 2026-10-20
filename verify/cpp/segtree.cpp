#include <atcoder/segtree>
#include <algorithm>
#include <cstdio>
using namespace atcoder;
using ll = long long;
ll op_max(ll a, ll b) { return std::max(a, b); }
ll e_max() { return 0; }
ll op_sum(ll a, ll b) { return a + b; }
ll e_sum() { return 0; }
ll K;
bool pred(ll s) { return s < K; }
int main() {
    int T; scanf("%d", &T);
    while (T--) {
        int mono, n, q; scanf("%d %d %d", &mono, &n, &q);
        segtree<ll, op_max, e_max> stm(n);
        segtree<ll, op_sum, e_sum> sts(n);
        while (q--) {
            int c; scanf("%d", &c);
            if (c == 0) { int p; ll x; scanf("%d %lld", &p, &x); if (mono == 0) stm.set(p, x); else sts.set(p, x); }
            else if (c == 1) { int l, r; scanf("%d %d", &l, &r); printf("%lld\n", mono == 0 ? stm.prod(l, r) : sts.prod(l, r)); }
            else if (c == 2) { printf("%lld\n", mono == 0 ? stm.all_prod() : sts.all_prod()); }
            else if (c == 3) { int l; scanf("%d %lld", &l, &K); printf("%d\n", mono == 0 ? stm.max_right<pred>(l) : sts.max_right<pred>(l)); }
            else { int r; scanf("%d %lld", &r, &K); printf("%d\n", mono == 0 ? stm.min_left<pred>(r) : sts.min_left<pred>(r)); }
        }
    }
}
