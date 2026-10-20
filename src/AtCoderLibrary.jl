"""
    AtCoderLibrary

AtCoder Library (ACL) の Julia 移植。

設計方針(詳細は `acl-julia-design-notes.md`):
- 関数の意味論・計算量保証は C++ 版に準拠(検証可能性のため)
- 外部 API は 1-indexed、区間は閉区間(inclusive、`l:r` の `UnitRange`)
- 破壊的操作には `!` を付ける
- SegTree は `*` / `one`(モノイド)、FenwickTree は `+` / `zero` / `-`(可換群)を
  デフォルトの記法とし、演算のパラメータ化で一般化する
- 境界探索 (`max_right` / `min_left`) は true 側ラベルを返す(`searchsortedlast` 流)。
  条件を満たす区間が空区間のみの場合、`max_right` は `l - 1`、`min_left` は `r + 1`
"""
module AtCoderLibrary

include("modint.jl")
include("math.jl")
include("dsu.jl")
include("fenwicktree.jl")
include("segtree.jl")
include("lazysegtree.jl")
include("string.jl")
include("convolution.jl")
include("scc.jl")
include("twosat.jl")
include("maxflow.jl")
include("mincostflow.jl")

# modint
export ModInt, ModInt998244353, ModInt1000000007, val
# math
export pow_mod, inv_mod, crt, floor_sum
# dsu
export DSU, same, leader, group_size, groups
# fenwicktree
export FenwickTree, prefix, mult!, add!
# segtree / lazysegtree
export SegTree, LazySegTree, set!, apply!, max_right, min_left
# string
export suffix_array, lcp_array, z_algorithm
# convolution
export convolution, convolution_ll
# scc
export SCCGraph, add_edge!, scc
# twosat
export TwoSAT, add_clause!, satisfiable!, answer
# maxflow
export MFGraph, MFEdge, flow!, min_cut, get_edge, edges, change_edge!
# mincostflow
export MCFGraph, MCFEdge, slope!

end # module
