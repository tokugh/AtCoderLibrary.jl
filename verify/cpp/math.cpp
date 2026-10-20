#include <atcoder/math>
#include <cstdio>
#include <vector>
using namespace atcoder;
using ll = long long;
int main() {
    int T; scanf("%d", &T);
    while (T--) {
        int type; scanf("%d", &type);
        if (type == 0) {
            ll n, m, a, b; scanf("%lld %lld %lld %lld", &n, &m, &a, &b);
            printf("%lld\n", floor_sum(n, m, a, b));
        } else {
            int k; scanf("%d", &k);
            std::vector<ll> r(k), m(k);
            for (auto& x : r) scanf("%lld", &x);
            for (auto& x : m) scanf("%lld", &x);
            auto p = crt(r, m);
            printf("%lld %lld\n", p.first, p.second);
        }
    }
}
