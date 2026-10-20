# K - Range Affine Range Sum
# S = (和, 長さ), F = (b, c) : x ↦ b*x + c の LazySegTree(mod 998244353)。
# 入力の区間は 0-indexed 半開 [l, r) なので 1-indexed 閉区間 (l+1):r に変換する。
aff_op(x, y) = (x[1] + y[1], x[2] + y[2])
aff_map(f, x) = (f[1] * x[1] + f[2] * x[2], x[2])
aff_comp(f, g) = (f[1] * g[1], f[1] * g[2] + f[2])

function (@main)(ARGS)
    input!()
    M = ModInt998244353
    N = nextI(); Q = nextI()
    a = [(M(nextI()), one(M)) for _ in 1:N]
    st = LazySegTree(aff_op, (zero(M), zero(M)), aff_map, aff_comp,
                     (one(M), zero(M)), a)
    for _ in 1:Q
        t = nextI()
        if t == 0
            l = nextI(); r = nextI(); b = nextI(); c = nextI()
            apply!(st, (l+1):r, (M(b), M(c)))
        else
            l = nextI(); r = nextI()
            println(val(prod(st, (l+1):r)[1]))
        end
    end
end
