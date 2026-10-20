using AtCoderLibrary
const toks = split(read(stdin, String))
const pos = Ref(0)
nxti() = (pos[] += 1; parse(Int, toks[pos[]]))

const M = ModInt998244353
aff_op(x, y) = (x[1] + y[1], x[2] + y[2])
aff_map(f, x) = (f[1] * x[1] + f[2] * x[2], x[2])
aff_comp(f, g) = (f[1] * g[1], f[1] * g[2] + f[2])

const out = IOBuffer()
for _ in 1:nxti()
    n = nxti(); q = nxti()
    st = LazySegTree(aff_op, (zero(M), zero(M)), aff_map, aff_comp,
                     (one(M), zero(M)), [(zero(M), one(M)) for _ in 1:n])
    for _ in 1:q
        c = nxti()
        if c == 0
            l = nxti(); r = nxti(); b = nxti(); cc = nxti()
            apply!(st, (l+1):r, (M(b), M(cc)))
        elseif c == 1
            l = nxti(); r = nxti()
            println(out, val(prod(st, (l+1):r)[1]))
        elseif c == 2
            p = nxti(); x = nxti()
            st[p+1] = (M(x), one(M))
        elseif c == 3
            p = nxti()
            println(out, val(st[p+1][1]))
        else
            l = nxti(); k = nxti()
            println(out, max_right(st, l + 1, s -> val(s[1]) < k))
        end
    end
end
print(String(take!(out)))
