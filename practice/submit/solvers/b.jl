# B - Fenwick Tree
# https://atcoder.jp/contests/practice2/tasks/practice2_b
function (@main)(ARGS)
    input!()
    n = nextI(); q = nextI()
    a = [nextI() for _ in 1:n]
    ft = FenwickTree(a)
    for _ in 1:q
        t = nextI()
        if t == 0
            p = nextI() + 1          # 0-indexed → 1-indexed
            x = nextI()
            add!(ft, p, x)
        else
            l = nextI()
            r = nextI()
            println(sum(ft, (l+1):r))   # 半開 [l, r) → 閉 l+1:r
        end
    end
end
