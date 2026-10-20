# ==== 入力(TokenIO ワンライナー版)====
const _IN = Ref(""); const _POS = Ref(1)
input!() = (_IN[] = read(stdin, String); _POS[] = 1; nothing)
@inline function nextI(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; neg = false; @inbounds if p <= n && codeunit(s, p) == 0x2d; neg = true; p += 1; end; x = 0; @inbounds while p <= n; c = codeunit(s, p); (0x30 <= c <= 0x39) || break; x = 10x + Int(c - 0x30); p += 1; end; _POS[] = p; return neg ? -x : x; end
@inline function nextS(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; p > n && return SubString(s, 1, 0); q = p; @inbounds while q <= n && codeunit(s, q) > 0x20; q += 1; end; _POS[] = q; return SubString(s, p, thisind(s, q - 1)); end
nextF() = parse(Float64, nextS())
function nextC(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; p > n && return '\0'; c = s[p]; _POS[] = nextind(s, p); return c; end

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

# ==== ライブラリ: lazysegtree.jl ====
# Library: https://github.com/tokugh/AtCoderLibrary.jl
"""
    LazySegTree(op, e, mapping, composition, id, v::AbstractVector)
    LazySegTree(op, e, mapping, composition, id, n::Integer)

遅延評価セグメント木。モノイド `(S, op, e)` と、それに作用する写像モノイド
`(F, composition, id)` の組で、区間作用と区間積がともに O(log n)。

- `mapping(f::F, x::S) -> S` : 作用 `f(x)`
- `composition(f::F, g::F) -> F` : 合成 `f ∘ g`(`f` を **後から** 適用)
- `id::F` : 恒等写像

C++ 版 `lazy_segtree<S, op, e, F, mapping, composition, id>` と同じ意味論。
写像を callable struct にして `mapping = (f, x) -> f(x)`、`composition = ∘` と
書く枠組みにも乗るが、`∘` は合成のたびに型が育つ(`ComposedFunction`)ため
競プロ用途では閉じた合成関数を渡すこと。

- 添え字は 1-indexed、区間は閉区間:`prod(st, l:r)`、`apply!(st, l:r, f)`
- 一点は `st[i]` / `st[i] = x`(= `set!`)/ `apply!(st, i, f)`
- 境界探索は [`max_right`](@ref) / [`min_left`](@ref)(SegTree と同じ規約:
  true 側ラベル、空なら `l - 1` / `r + 1`)

# 例(区間加算・区間 min)
```julia
st = LazySegTree(min, typemax(Int), +, +, 0, [3, 1, 4, 1, 5])
apply!(st, 2:4, 10)     # a[2:4] .+= 10
prod(st, 1:5)           # 3
```
"""
struct LazySegTree{S,F,Op,Mapping,Composition}
    op::Op
    e::S
    mapping::Mapping
    composition::Composition
    id::F
    n::Int
    sz::Int
    log::Int
    d::Vector{S}    # 1-indexed ヒープ配置(SegTree と同じ)
    lz::Vector{F}   # 内部ノード 1..sz-1 の遅延作用
end

# op・mapping・composition は型変数で注釈する。無注釈だと「格納されるだけの
# Function 引数には特殊化しない」ヒューリスティックが働き、precompile の静的推論が
# 内部コンストラクタと _update! まで届かず pkgimage に焼き残る
function LazySegTree(op::Op, e::S, mapping::Mapping, composition::Composition,
                     id::F, v::AbstractVector) where {S,F,Op,Mapping,Composition}
    n = length(v)
    log = n <= 1 ? 0 : 8 * sizeof(Int) - leading_zeros(n - 1)
    sz = 1 << log
    d = fill(e, 2sz - 1)
    lz = fill(id, sz - 1)
    @inbounds for i in 1:n
        d[sz+i-1] = convert(S, v[i])
    end
    st = LazySegTree{S,F,Op,Mapping,Composition}(
        op, e, mapping, composition, id, n, sz, log, d, lz)
    @inbounds for k in (sz-1):-1:1
        _update!(st, k)
    end
    return st
end
LazySegTree(op::Op, e::S, mapping::Mapping, composition::Composition,
            id::F, n::Integer) where {S,F,Op,Mapping,Composition} =
    LazySegTree(op, e, mapping, composition, id, fill(e, Int(n)))

Base.length(st::LazySegTree) = st.n
Base.eltype(::Type{<:LazySegTree{S}}) where {S} = S

@inline _update!(st::LazySegTree, k::Int) = @inbounds st.d[k] = st.op(st.d[2k], st.d[2k+1])

@inline function _all_apply!(st::LazySegTree{S,F}, k::Int, f::F) where {S,F}
    @inbounds st.d[k] = st.mapping(f, st.d[k])
    k < st.sz && (@inbounds st.lz[k] = st.composition(f, st.lz[k]))
    return nothing
end

@inline function _push!(st::LazySegTree, k::Int)
    @inbounds f = st.lz[k]
    _all_apply!(st, 2k, f)
    _all_apply!(st, 2k + 1, f)
    @inbounds st.lz[k] = st.id
    return nothing
end

"""
    set!(st::LazySegTree, i, x)

`i` 番目の要素を `x` に更新する。O(log n)。`st[i] = x` と等価。
"""
function set!(st::LazySegTree{S}, i::Integer, x) where {S}
    @boundscheck 1 <= i <= st.n || throw(BoundsError(st, i))
    p = st.sz + Int(i) - 1
    for j in st.log:-1:1
        _push!(st, p >> j)
    end
    @inbounds st.d[p] = convert(S, x)
    for j in 1:st.log
        _update!(st, p >> j)
    end
    return x
end
Base.setindex!(st::LazySegTree, x, i::Integer) = set!(st, i, x)

function Base.getindex(st::LazySegTree, i::Integer)
    @boundscheck 1 <= i <= st.n || throw(BoundsError(st, i))
    p = st.sz + Int(i) - 1
    for j in st.log:-1:1
        _push!(st, p >> j)
    end
    return @inbounds st.d[p]
end

"""
    prod(st::LazySegTree, r::UnitRange) -> S
    prod(st::LazySegTree) -> S

閉区間 `l:r` の積。空区間は単位元 `e`。引数なしは全区間。O(log n)。
"""
function Base.prod(st::LazySegTree{S}, r::UnitRange{<:Integer}) where {S}
    isempty(r) && return st.e
    lo, hi = Int(first(r)), Int(last(r))
    @boundscheck (1 <= lo && hi <= st.n) || throw(BoundsError(st, r))
    l = st.sz + lo - 1
    rr = st.sz + hi   # 内部では半開区間 [l, rr)
    for i in st.log:-1:1
        ((l >> i) << i) != l && _push!(st, l >> i)
        ((rr >> i) << i) != rr && _push!(st, (rr - 1) >> i)
    end
    sml = st.e
    smr = st.e
    @inbounds while l < rr
        if isodd(l)
            sml = st.op(sml, st.d[l])
            l += 1
        end
        if isodd(rr)
            rr -= 1
            smr = st.op(st.d[rr], smr)
        end
        l >>= 1
        rr >>= 1
    end
    return st.op(sml, smr)
end
Base.prod(st::LazySegTree) = @inbounds st.d[1]

"""
    apply!(st::LazySegTree, i::Integer, f)
    apply!(st::LazySegTree, r::UnitRange, f)

一点 `i` または閉区間 `l:r` に作用 `f` を適用する(`a[i] ← mapping(f, a[i])`)。
空区間には何もしない。O(log n)。
"""
function apply!(st::LazySegTree{S,F}, i::Integer, f) where {S,F}
    @boundscheck 1 <= i <= st.n || throw(BoundsError(st, i))
    p = st.sz + Int(i) - 1
    for j in st.log:-1:1
        _push!(st, p >> j)
    end
    @inbounds st.d[p] = st.mapping(convert(F, f), st.d[p])
    for j in 1:st.log
        _update!(st, p >> j)
    end
    return st
end

function apply!(st::LazySegTree{S,F}, r::UnitRange{<:Integer}, f) where {S,F}
    isempty(r) && return st
    lo, hi = Int(first(r)), Int(last(r))
    @boundscheck (1 <= lo && hi <= st.n) || throw(BoundsError(st, r))
    fc = convert(F, f)
    l = st.sz + lo - 1
    rr = st.sz + hi   # 半開区間 [l, rr)
    for i in st.log:-1:1
        ((l >> i) << i) != l && _push!(st, l >> i)
        ((rr >> i) << i) != rr && _push!(st, (rr - 1) >> i)
    end
    l2, rr2 = l, rr
    while l2 < rr2
        if isodd(l2)
            _all_apply!(st, l2, fc)
            l2 += 1
        end
        if isodd(rr2)
            rr2 -= 1
            _all_apply!(st, rr2, fc)
        end
        l2 >>= 1
        rr2 >>= 1
    end
    for i in 1:st.log
        ((l >> i) << i) != l && _update!(st, l >> i)
        ((rr >> i) << i) != rr && _update!(st, (rr - 1) >> i)
    end
    return st
end

"""
    max_right(st::LazySegTree, l, f) -> Int
    max_right(f, st::LazySegTree, l) -> Int

`f(prod(st, l:r)) == true` を満たす最大の `r`(true 側ラベル)。満たす区間が
空区間しかない場合は `l - 1`。事前条件 `f(e) == true`。`f` が単調のときに限り
「最大」が保証される。O(log n)。規約は `SegTree` の [`max_right`](@ref) と同一。
"""
function max_right(f, st::LazySegTree{S}, l::Integer) where {S}
    @boundscheck 1 <= l <= st.n + 1 || throw(BoundsError(st, l))
    @assert f(st.e) "max_right の事前条件 f(e) == true を満たしていません"
    l > st.n && return st.n
    p = st.sz + Int(l) - 1
    for j in st.log:-1:1
        _push!(st, p >> j)
    end
    sm = st.e
    @inbounds while true
        while iseven(p)
            p >>= 1
        end
        if !f(st.op(sm, st.d[p]))
            while p < st.sz
                _push!(st, p)
                p <<= 1
                if f(st.op(sm, st.d[p]))
                    sm = st.op(sm, st.d[p])
                    p += 1
                end
            end
            return p - st.sz
        end
        sm = st.op(sm, st.d[p])
        p += 1
        (p & -p) == p && break
    end
    return st.n
end
max_right(st::LazySegTree, l::Integer, f) = max_right(f, st, l)

"""
    min_left(st::LazySegTree, r, f) -> Int
    min_left(f, st::LazySegTree, r) -> Int

`f(prod(st, l:r)) == true` を満たす最小の `l`。満たす区間が空区間しかない場合は
`r + 1`。事前条件 `f(e) == true`。O(log n)。規約は `SegTree` の
[`min_left`](@ref) と同一。
"""
function min_left(f, st::LazySegTree{S}, r::Integer) where {S}
    @boundscheck 0 <= r <= st.n || throw(BoundsError(st, r))
    @assert f(st.e) "min_left の事前条件 f(e) == true を満たしていません"
    r == 0 && return 1
    p = st.sz + Int(r)
    for j in st.log:-1:1
        _push!(st, (p - 1) >> j)
    end
    sm = st.e
    @inbounds while true
        p -= 1
        while p > 1 && isodd(p)
            p >>= 1
        end
        if !f(st.op(st.d[p], sm))
            while p < st.sz
                _push!(st, p)
                p = 2p + 1
                if f(st.op(st.d[p], sm))
                    sm = st.op(st.d[p], sm)
                    p -= 1
                end
            end
            return p + 2 - st.sz
        end
        sm = st.op(st.d[p], sm)
        (p & -p) == p && break
    end
    return 1
end
min_left(st::LazySegTree, r::Integer, f) = min_left(f, st, r)
