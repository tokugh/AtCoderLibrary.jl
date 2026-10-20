#include <atcoder/dsu>
#include <cstdio>
using namespace atcoder;
int main() {
    int T; scanf("%d", &T);
    while (T--) {
        int n, q; scanf("%d %d", &n, &q);
        dsu d(n);
        while (q--) {
            int c, u, v = 0; scanf("%d %d", &c, &u);
            if (c != 2) scanf("%d", &v);
            if (c == 0) printf("%d\n", d.merge(u, v));
            else if (c == 1) printf("%d\n", d.same(u, v) ? 1 : 0);
            else printf("%d\n", d.size(u));
        }
    }
}
