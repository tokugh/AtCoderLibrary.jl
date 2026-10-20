#include <atcoder/lazysegtree>
#include <atcoder/modint>
#include <cstdio>
#include <vector>
using namespace atcoder;
using ll = long long;
using mint = modint998244353;
struct S { mint a; int size; };
struct F { mint b, c; };
S op(S l, S r) { return {l.a + r.a, l.size + r.size}; }
S e() { return {0, 0}; }
S mapping(F f, S x) { return {f.b * x.a + f.c * x.size, x.size}; }
F composition(F f, F g) { return {f.b * g.b, f.b * g.c + f.c}; }
F id() { return {1, 0}; }
ll K;
bool pred(S s) { return s.a.val() < K; }
int main() {
    int T; scanf("%d", &T);
    while (T--) {
        int n, q; scanf("%d %d", &n, &q);
        std::vector<S> init(n, S{0, 1});
        lazy_segtree<S, op, e, F, mapping, composition, id> st(init);
        while (q--) {
            int c; scanf("%d", &c);
            if (c == 0) { int l, r; ll b, cc; scanf("%d %d %lld %lld", &l, &r, &b, &cc); st.apply(l, r, F{b, cc}); }
            else if (c == 1) { int l, r; scanf("%d %d", &l, &r); printf("%u\n", st.prod(l, r).a.val()); }
            else if (c == 2) { int p; ll x; scanf("%d %lld", &p, &x); st.set(p, S{x, 1}); }
            else if (c == 3) { int p; scanf("%d", &p); printf("%u\n", st.get(p).a.val()); }
            else { int l; scanf("%d %lld", &l, &K); printf("%d\n", st.max_right<pred>(l)); }
        }
    }
}
