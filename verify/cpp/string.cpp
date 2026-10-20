#include <atcoder/string>
#include <cstdio>
#include <string>
#include <vector>
using namespace atcoder;
void put(const std::vector<int>& v) {
    for (size_t i = 0; i < v.size(); i++) printf("%d%c", v[i], i + 1 == v.size() ? '\n' : ' ');
    if (v.empty()) printf("\n");
}
int main() {
    int T; scanf("%d", &T);
    while (T--) {
        int type; scanf("%d", &type);
        if (type == 0) {
            char buf[300]; scanf("%s", buf);
            std::string s(buf);
            auto sa = suffix_array(s);
            put(sa); put(lcp_array(s, sa)); put(z_algorithm(s));
        } else {
            int n; scanf("%d", &n);
            std::vector<int> v(n);
            for (auto& x : v) scanf("%d", &x);
            auto sa = suffix_array(v);
            put(sa); put(lcp_array(v, sa)); put(z_algorithm(v));
        }
    }
}
