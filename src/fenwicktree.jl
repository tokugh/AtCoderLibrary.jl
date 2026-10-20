"""
    FenwickTree(v::AbstractVector{S})   # op = +, e = zero(S), invop = -
    FenwickTree{S}(n::Integer)          # 同上、全要素 zero(S)
    FenwickTree(op, e, v_or_n)          # 可換モノイド(invop なし)
    FenwickTree(op, e, invop, v_or_n)   # 可換群(invop あり)
    FenwickTree{S}(op, e, [invop,] v_or_n)  # 要素型 S を明示(Union{Missing,Int} など)

Fenwick Tree(Binary Indexed Tree)。一点作用と prefix 集約が O(log n)。

Fenwick Tree が本質的に扱うのは **可換モノイド** であり、機能は二層に分かれる:

1. 一点作用 [`mult!`](@ref) と prefix 集約 [`prefix`](@ref) — 可換モノイドで可能
2. 区間クエリ `sum` / `prod`・一点取得 `ft[i]`・一点代入 [`set!`](@ref) —
   演算が逆元 `invop` を持つ場合(可換群)に導出される

デフォルトは C++ 版 `fenwick_tree<T>` と同じ加法群(`+` / `zero` / `-`)で、
`sum(ft, l:r)` / `add!(ft, i, x)` が使える。逆元がない演算(`max` / `min` など)は
`invop` を省いた 3 引数形 `FenwickTree(op, e, v_or_n)`(`SegTree(op, e, v)` と同じ並び)
で書く — このとき区間クエリ系は呼んだ時点でエラーになる
(「Fenwick に min の区間クエリは載らない」が API の形で現れる)。
逆元を明示する 4 引数形は `FenwickTree(op, e, invop, v_or_n)`。

- 添え字は 1-indexed、区間は閉区間(`l:r` の `UnitRange`)
- `op` は **可換** であること(非可換モノイドは SegTree の領分)
- `FenwickTree(+, 0, v)` と 3 引数で書くと「逆元なしの和」になり `sum(ft, l:r)` は
  エラー。加法群として使うなら 1 引数形か 4 引数形で
- 無印形の要素型は `S = typeof(e)`。`e` の型がそのまま要素型にならない場合
  (`missing` を単位元にする `Union{Missing,T}` モノイドなど)は `{S}` 明示形で

# 例
```julia
ft = FenwickTree(zeros(Int, 5))
add!(ft, 2, 10)
sum(ft, 1:3)              # 10

# max モノイド:point chmax + prefix max(区間クエリは取れない)
mft = FenwickTree(max, typemin(Int), [3, 1, 4, 1, 5])
mult!(mft, 2, 10)         # a[2] ← max(a[2], 10)
prefix(mft, 3)            # 10
```
"""
struct FenwickTree{S,Op,Inv}
    op::Op
    e::S
    invop::Inv   # S -> S、または nothing(逆元なし=可換モノイドまで)
    n::Int
    data::Vector{S}
end

# op・invop は型変数で注釈する。無注釈だと「格納されるだけの Function 引数には
# 特殊化しない」ヒューリスティックが働き、precompile の静的推論が内部コンストラクタ
# まで届かず pkgimage に焼き残る。
# 実体は S 明示形に一本化し、無印形は e の型から S を推論して委譲する
FenwickTree{S}(op::Op, e, invop::Inv, n::Integer) where {S,Op,Inv} =
    FenwickTree{S,Op,Inv}(op, e, invop, Int(n), fill!(Vector{S}(undef, Int(n)), e))
function FenwickTree{S}(op::Op, e, invop::Inv, v::AbstractVector) where {S,Op,Inv}
    n = length(v)
    data = Vector{S}(undef, n)
    @inbounds for i in 1:n
        data[i] = convert(S, v[i])
    end
    # O(n) 構築:各ノードの積を親ブロックへ畳み上げる
    @inbounds for i in 1:n
        j = i + (i & -i)
        j <= n && (data[j] = op(data[j], data[i]))
    end
    return FenwickTree{S,Op,Inv}(op, e, invop, n, data)
end
# 可換モノイド形: invop 省略 = nothing(SegTree(op, e, v) と同じ並び)
FenwickTree{S}(op::Op, e, n::Integer) where {S,Op} = FenwickTree{S}(op, e, nothing, n)
FenwickTree{S}(op::Op, e, v::AbstractVector) where {S,Op} = FenwickTree{S}(op, e, nothing, v)
FenwickTree(op::Op, e::S, invop::Inv, n::Integer) where {S,Op,Inv} = FenwickTree{S}(op, e, invop, n)
FenwickTree(op::Op, e::S, invop::Inv, v::AbstractVector) where {S,Op,Inv} = FenwickTree{S}(op, e, invop, v)
FenwickTree(op::Op, e::S, n::Integer) where {S,Op} = FenwickTree{S}(op, e, nothing, n)
FenwickTree(op::Op, e::S, v::AbstractVector) where {S,Op} = FenwickTree{S}(op, e, nothing, v)
FenwickTree{S}(n::Integer) where {S} = FenwickTree(+, zero(S), -, n)
FenwickTree(v::AbstractVector{S}) where {S} = FenwickTree(+, zero(S), -, v)

Base.length(ft::FenwickTree) = ft.n
Base.eltype(::Type{FenwickTree{S,Op,Inv}}) where {S,Op,Inv} = S

_fenwick_noinv_error() = throw(ArgumentError(
    "この FenwickTree は逆元 (invop) を持たないため、区間クエリ・一点取得・set! は使えません。" *
    "prefix と mult! のみ利用できます"))

"""
    mult!(ft::FenwickTree, i, x)

一点作用:`a[i] ← op(a[i], x)`。O(log n)。可換モノイドで無条件に使える。
加法群のときのエイリアスは [`add!`](@ref)。
"""
function mult!(ft::FenwickTree{S}, i::Integer, x) where {S}
    @boundscheck 1 <= i <= ft.n || throw(BoundsError(ft, i))
    xs = convert(S, x)
    j = Int(i)
    @inbounds while j <= ft.n
        ft.data[j] = ft.op(ft.data[j], xs)
        j += j & -j
    end
    return ft
end

"""
    add!(ft::FenwickTree, i, x)

`a[i] += x`。加法群(デフォルト構成)の FenwickTree 専用のエイリアス。O(log n)。
"""
add!(ft::FenwickTree{S,typeof(+)}, i::Integer, x) where {S} = mult!(ft, i, x)

"""
    prefix(ft::FenwickTree, r) -> S

prefix 集約 `op(a[1], ..., a[r])` を返す。`r == 0` は単位元。O(log n)。
可換モノイドで無条件に使える(逆元不要)。
"""
function prefix(ft::FenwickTree{S}, r::Integer) where {S}
    @boundscheck 0 <= r <= ft.n || throw(BoundsError(ft, r))
    s = ft.e
    j = Int(r)
    @inbounds while j > 0
        s = ft.op(s, ft.data[j])
        j -= j & -j
    end
    return s
end

"""
    prod(ft::FenwickTree, r::UnitRange) -> S
    prod(ft::FenwickTree) -> S

閉区間 `l:r` の積。`prefix(r)` と `invop(prefix(l-1))` の合成で求めるため
**逆元が必要**(`invop === nothing` なら `ArgumentError`)。空区間は単位元。
O(log n)。加法群のときは [`sum`](@ref) と同じ。
"""
function Base.prod(ft::FenwickTree{S,Op,Inv}, r::UnitRange{<:Integer}) where {S,Op,Inv}
    Inv === Nothing && _fenwick_noinv_error()
    isempty(r) && return ft.e
    lo, hi = Int(first(r)), Int(last(r))
    @boundscheck (1 <= lo && hi <= ft.n) || throw(BoundsError(ft, r))
    return ft.op(ft.invop(prefix(ft, lo - 1)), prefix(ft, hi))
end
Base.prod(ft::FenwickTree) = prefix(ft, ft.n)

"""
    sum(ft::FenwickTree, r::UnitRange) -> S
    sum(ft::FenwickTree) -> S

閉区間 `l:r` の総和(加法群の FenwickTree 専用)。空区間は `zero(S)`。O(log n)。
"""
Base.sum(ft::FenwickTree{S,typeof(+)}, r::UnitRange{<:Integer}) where {S} = prod(ft, r)
Base.sum(ft::FenwickTree{S,typeof(+)}) where {S} = prefix(ft, ft.n)

"""
    getindex(ft::FenwickTree, i) -> S

一点取得 `a[i]`(= `prod(ft, i:i)`)。逆元が必要。O(log n)。
"""
Base.getindex(ft::FenwickTree, i::Integer) = prod(ft, Int(i):Int(i))

"""
    set!(ft::FenwickTree, i, x)

一点代入 `a[i] ← x`。現在値の逆元を作用させてから `x` を作用させるため
**逆元が必要**。O(log n)。`ft[i] = x` と等価。
"""
function set!(ft::FenwickTree{S,Op,Inv}, i::Integer, x) where {S,Op,Inv}
    Inv === Nothing && _fenwick_noinv_error()
    cur = ft[i]
    return mult!(ft, i, ft.op(convert(S, x), ft.invop(cur)))
end
Base.setindex!(ft::FenwickTree, x, i::Integer) = set!(ft, i, x)
