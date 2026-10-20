"""
    SegTree(op, e, v::AbstractVector)
    SegTree(op, e, n::Integer)
    SegTree{S}(op, e, v_or_n)       # 要素型 S を明示(Union{Missing,Int} など)
    SegTree(v::AbstractVector{S})   # op = *, e = one(S)
    SegTree{S}(n::Integer)          # op = *, e = one(S)

モノイド `(S, op, e)` 上のセグメント木。一点更新と区間積が O(log n)。

デフォルトの記法は乗法(`*` / `one`):`SegTree(v)` は要素型の `*` で畳み込む。
非可換モノイド(行列積など)も可。`max` のような演算はラッパー型で載せる:

```julia
struct MaxInt x::Int end
Base.:*(a::MaxInt, b::MaxInt) = MaxInt(max(a.x, b.x))
Base.one(::Type{MaxInt}) = MaxInt(typemin(Int))
st = SegTree([MaxInt(x) for x in data])
```

任意の演算は `SegTree(op, e, v)` でパラメータ化する(演算は型パラメータに
埋め込まれるため動的ディスパッチのコストはない)。無印形の要素型は
`S = typeof(e)`。`e` の型がそのまま要素型にならない場合は `{S}` 明示形で:

```julia
# missing を単位元にした min モノイド(typemax の番兵値が不要)
mst = SegTree{Union{Missing,Int}}(
    (a, b) -> ismissing(a) ? b : ismissing(b) ? a : min(a, b),
    missing, [3, 1, 4])
prod(mst, 1:3)   # 1
```

- 添え字は 1-indexed、区間は閉区間:`prod(st, l:r)` は `prod(a[l:r])` と同じ意味
- 一点更新は `st[i] = x`(= `set!(st, i, x)`)、取得は `st[i]`
- 全区間の積は `prod(st)`
- 境界探索は [`max_right`](@ref) / [`min_left`](@ref)
"""
struct SegTree{S,Op}
    op::Op
    e::S
    n::Int
    sz::Int
    log::Int
    d::Vector{S}   # 1-indexed ヒープ配置:根が 1、子が 2k と 2k+1、葉 i は sz + i - 1
end

# op は型変数で注釈する。無注釈だと「格納されるだけの Function 引数には特殊化
# しない」ヒューリスティックが働き、precompile の静的推論が内部コンストラクタと
# _update! まで届かず pkgimage に焼き残る。
# 実体は S 明示形に一本化し、無印形は e の型から S を推論して委譲する
function SegTree{S}(op::Op, e, v::AbstractVector) where {S,Op}
    n = length(v)
    log = n <= 1 ? 0 : 8 * sizeof(Int) - leading_zeros(n - 1)
    sz = 1 << log
    d = fill!(Vector{S}(undef, 2sz - 1), e)
    @inbounds for i in 1:n
        d[sz+i-1] = convert(S, v[i])
    end
    st = SegTree{S,Op}(op, e, n, sz, log, d)
    @inbounds for k in (sz-1):-1:1
        _update!(st, k)
    end
    return st
end
SegTree{S}(op::Op, e, n::Integer) where {S,Op} =
    SegTree{S}(op, e, fill!(Vector{S}(undef, Int(n)), e))
SegTree(op::Op, e::S, v::AbstractVector) where {S,Op} = SegTree{S}(op, e, v)
SegTree(op::Op, e::S, n::Integer) where {S,Op} = SegTree{S}(op, e, n)
SegTree(v::AbstractVector{S}) where {S} = SegTree(*, one(S), v)
SegTree{S}(n::Integer) where {S} = SegTree(*, one(S), fill(one(S), Int(n)))

Base.length(st::SegTree) = st.n
Base.eltype(::Type{SegTree{S,Op}}) where {S,Op} = S

@inline _update!(st::SegTree, k::Int) = @inbounds st.d[k] = st.op(st.d[2k], st.d[2k+1])

"""
    set!(st::SegTree, i, x)

`i` 番目の要素を `x` に更新する。O(log n)。`st[i] = x` と等価。
"""
function set!(st::SegTree{S,Op}, i::Integer, x::S) where {S,Op}
    @boundscheck 1 <= i <= st.n || throw(BoundsError(st, i))
    p = st.sz + Int(i) - 1
    @inbounds st.d[p] = x
    for _ in 1:st.log
        p >>= 1
        _update!(st, p)
    end
    return x
end
# x::S に厳密一致しない場合は変換して上のメソッドへ。x を無注釈のまま格納すると
# 複雑な呼び出し元で setindex! が動的呼び出しに残り pkgimage に焼き残る
function set!(st::SegTree{S}, i::Integer, x) where {S}
    set!(st, i, convert(S, x)::S)
    return x
end
Base.setindex!(st::SegTree{S,Op}, x::S, i::Integer) where {S,Op} = set!(st, i, x)
function Base.setindex!(st::SegTree{S}, x, i::Integer) where {S}
    setindex!(st, convert(S, x)::S, i)
    return x
end

function Base.getindex(st::SegTree, i::Integer)
    @boundscheck 1 <= i <= st.n || throw(BoundsError(st, i))
    return @inbounds st.d[st.sz+Int(i)-1]
end

"""
    prod(st::SegTree, r::UnitRange) -> S
    prod(st::SegTree) -> S

閉区間 `l:r` の積 `op(a[l], ..., a[r])` を返す。O(log n)。
空区間(`l > r`)では単位元 `e` を返す(空区間を渡すことの意味の説明責任は
呼び出し側にある)。引数なしは全区間の積(C++ 版 `all_prod`)。
"""
function Base.prod(st::SegTree{S}, r::UnitRange{<:Integer}) where {S}
    isempty(r) && return st.e
    lo, hi = Int(first(r)), Int(last(r))
    @boundscheck (1 <= lo && hi <= st.n) || throw(BoundsError(st, r))
    l = st.sz + lo - 1
    rr = st.sz + hi   # 内部では半開区間 [l, rr) に変換して畳む
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
Base.prod(st::SegTree) = @inbounds st.d[1]

"""
    max_right(st::SegTree, l, f) -> Int
    max_right(f, st::SegTree, l) -> Int

`f(prod(st, l:r)) == true` を満たす最大の `r` を返す(`searchsortedlast` 流の
true 側ラベル)。満たす区間が空区間しかない場合は `l - 1` を返す(このとき
`prod` は単位元とみなす)。事前条件は `f(e) == true`。`f` が単調(区間を伸ばすと
true から false に一度だけ切り替わる)のときに限り「最大」が保証される。O(log n)。

do 記法も使える:`max_right(st, l) do s; s.x < 100; end`
"""
function max_right(f, st::SegTree{S}, l::Integer) where {S}
    @boundscheck 1 <= l <= st.n + 1 || throw(BoundsError(st, l))
    @assert f(st.e) "max_right の事前条件 f(e) == true を満たしていません"
    l > st.n && return st.n
    p = st.sz + Int(l) - 1
    sm = st.e
    @inbounds while true
        while iseven(p)
            p >>= 1
        end
        if !f(st.op(sm, st.d[p]))
            while p < st.sz
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
max_right(st::SegTree, l::Integer, f) = max_right(f, st, l)

"""
    min_left(st::SegTree, r, f) -> Int
    min_left(f, st::SegTree, r) -> Int

`f(prod(st, l:r)) == true` を満たす最小の `l` を返す。満たす区間が空区間しか
ない場合は `r + 1` を返す。事前条件は `f(e) == true`。`f` が単調のときに限り
「最小」が保証される。O(log n)。
"""
function min_left(f, st::SegTree{S}, r::Integer) where {S}
    @boundscheck 0 <= r <= st.n || throw(BoundsError(st, r))
    @assert f(st.e) "min_left の事前条件 f(e) == true を満たしていません"
    r == 0 && return 1
    p = st.sz + Int(r)
    sm = st.e
    @inbounds while true
        p -= 1
        while p > 1 && isodd(p)
            p >>= 1
        end
        if !f(st.op(st.d[p], sm))
            while p < st.sz
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
min_left(st::SegTree, r::Integer, f) = min_left(f, st, r)
