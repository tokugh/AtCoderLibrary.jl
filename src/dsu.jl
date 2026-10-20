# Library: https://github.com/tokugh/AtCoderLibrary.jl
# ACL dsu.hpp の移植。素集合データ構造(union by size + 経路圧縮)。

"""
    DSU(n::Integer)

`n` 頂点(1-indexed)の素集合森(Union-Find)。

- [`merge!`](@ref Base.merge!) — 2 頂点の属するグループを併合
- [`same`](@ref) — 2 頂点が同じグループに属するか
- [`leader`](@ref) — 頂点の属するグループの代表
- [`group_size`](@ref) — 頂点の属するグループのサイズ
- [`groups`](@ref) — グループ分けの全体を取得

`groups` 以外の各操作はならし O(α(n))、`groups` は O(n)。

# 例
```julia
d = DSU(4)
merge!(d, 1, 2)
same(d, 1, 2)  # true
```
"""
struct DSU
    n::Int
    # 代表: -1 * グループサイズ、それ以外: 親の添え字
    parent_or_size::Vector{Int}
end

DSU(n::Integer) = DSU(Int(n), fill(-1, n))

Base.length(d::DSU) = d.n

@inline function _check_vertex(d::DSU, a::Integer)
    1 <= a <= d.n || throw(BoundsError(d, a))
    Int(a)
end

"""
    leader(d::DSU, a::Integer) -> Int

頂点 `a` の属するグループの代表を返す。経路圧縮を行う(破壊的だが観測可能な
状態は変わらないため `!` は付けない)。
"""
function leader(d::DSU, a::Integer)
    x = _check_vertex(d, a)
    p = d.parent_or_size
    root = x
    @inbounds while p[root] > 0
        root = p[root]
    end
    @inbounds while p[x] > 0
        nxt = p[x]
        p[x] = root
        x = nxt
    end
    root
end

"""
    merge!(d::DSU, a::Integer, b::Integer) -> Int

頂点 `a` と `b` の属するグループを併合し、併合後のグループの代表を返す。
既に同じグループの場合はその代表を返す。

Base の `merge!`(コレクション同士を併合して第一引数を返す)とは規約が異なり、
ACL の `merge` に合わせて代表(`Int`)を返す。
"""
function Base.merge!(d::DSU, a::Integer, b::Integer)
    x, y = leader(d, a), leader(d, b)
    x == y && return x
    p = d.parent_or_size
    @inbounds begin
        -p[x] < -p[y] && ((x, y) = (y, x))
        p[x] += p[y]
        p[y] = x
    end
    x
end

"""
    same(d::DSU, a::Integer, b::Integer) -> Bool

頂点 `a` と `b` が同じグループに属するかを返す。
"""
same(d::DSU, a::Integer, b::Integer) = leader(d, a) == leader(d, b)

"""
    group_size(d::DSU, a::Integer) -> Int

頂点 `a` の属するグループのサイズを返す。
"""
group_size(d::DSU, a::Integer) = -d.parent_or_size[leader(d, a)]

"""
    groups(d::DSU) -> Vector{Vector{Int}}

グループ分けの全体を返す。各グループ内は昇順、グループ同士は最小元の昇順。
計算量 O(n)。
"""
function groups(d::DSU)
    buckets = [Int[] for _ in 1:d.n]
    for i in 1:d.n
        push!(buckets[leader(d, i)], i)
    end
    filter!(!isempty, buckets)
    sort!(buckets; by = first)
    buckets
end
