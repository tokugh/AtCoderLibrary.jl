#include <atcoder/convolution>
#include <cstdio>
#include <vector>
using namespace atcoder;
using ll = long long;
int main() {
    int T; scanf("%d", &T);
    while (T--) {
        int mode, n, m; scanf("%d %d %d", &mode, &n, &m);
        std::vector<ll> a(n), b(m);
        for (auto& x : a) scanf("%lld", &x);
        for (auto& x : b) scanf("%lld", &x);
        std::vector<ll> c = mode == 0 ? convolution<998244353>(a, b) : convolution_ll(a, b);
        for (size_t i = 0; i < c.size(); i++) printf("%lld%c", c[i], i + 1 == c.size() ? '\n' : ' ');
        if (c.empty()) printf("\n");
    }
}
