# L - Lazy Segment Tree(区間反転・区間転倒数)
# S = (0 の個数, 1 の個数, 転倒数)。結合は inv = i1 + i2 + o1*z2(左の 1 × 右の 0)。
# F = Bool(反転するか)。反転で (1,0) ペアと (0,1) ペアが入れ替わるので
# inv' = z*o - inv。composition は xor、恒等写像は false。
inv_op(a, b) = (a[1] + b[1], a[2] + b[2], a[3] + b[3] + a[2] * b[1])
inv_map(f, s) = f ? (s[2], s[1], s[1] * s[2] - s[3]) : s

function (@main)(ARGS)
    input!()
    N = nextI(); Q = nextI()
    a = [nextI() == 0 ? (1, 0, 0) : (0, 1, 0) for _ in 1:N]
    st = LazySegTree(inv_op, (0, 0, 0), inv_map, ⊻, false, a)
    for _ in 1:Q
        t = nextI(); l = nextI(); r = nextI()
        if t == 1
            apply!(st, l:r, true)
        else
            println(prod(st, l:r)[3])
        end
    end
end
