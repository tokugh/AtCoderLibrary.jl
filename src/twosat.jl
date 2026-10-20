# twosat.jl — 2-SAT ソルバ (C++ 版 atcoder/twosat.hpp の移植)
#
# Reference:
# B. Aspvall, M. Plass, and R. Tarjan,
# A Linear-Time Algorithm for Testing the Truth of Certain Quantified Boolean
# Formulas

"""
    TwoSAT(n::Integer)

`n` 変数の 2-SAT。変数は 1-indexed(`x_1, …, x_n`)。
[`add_clause!`](@ref) で節を追加し、[`satisfiable!`](@ref) で充足可能性を判定、
可能なら [`answer`](@ref) で割り当てを取り出す。
"""
struct TwoSAT
    n::Int
    _answer::Vector{Bool}
    scc_graph::SCCGraph
end

TwoSAT(n::Integer) = TwoSAT(Int(n), fill(false, Int(n)), SCCGraph(2 * Int(n)))

# 内部: リテラル (x_i = value) に対応する頂点番号
_twosat_vertex(i::Int, value::Bool) = value ? 2i - 1 : 2i

"""
    add_clause!(ts::TwoSAT, i::Integer, f::Bool, j::Integer, g::Bool) -> ts

節 `(x_i = f) ∨ (x_j = g)` を追加する。`i`, `j` は `1:n` の範囲であること。

計算量: ならし O(1)。
"""
function add_clause!(ts::TwoSAT, i::Integer, f::Bool, j::Integer, g::Bool)
    1 <= i <= ts.n || throw(ArgumentError("i = $i が変数範囲 1:$(ts.n) 外です"))
    1 <= j <= ts.n || throw(ArgumentError("j = $j が変数範囲 1:$(ts.n) 外です"))
    add_edge!(ts.scc_graph, _twosat_vertex(Int(i), !f), _twosat_vertex(Int(j), g))
    add_edge!(ts.scc_graph, _twosat_vertex(Int(j), !g), _twosat_vertex(Int(i), f))
    ts
end

"""
    satisfiable!(ts::TwoSAT) -> Bool

これまでに追加した節をすべて満たす割り当てが存在するか判定する。
存在する場合、その割り当てを内部に保存する(そのため破壊的)。
割り当ては [`answer`](@ref) で取り出す。

計算量: 変数 n 個、節 m 個に対して O(n + m)。
"""
function satisfiable!(ts::TwoSAT)
    ids = _scc_ids(ts.scc_graph)[2]
    for i in 1:ts.n
        ids[2i-1] == ids[2i] && return false
        # x_i = true ⟺ (x_i = false) の成分がトポロジカル順で先
        ts._answer[i] = ids[2i] < ids[2i-1]
    end
    true
end

"""
    answer(ts::TwoSAT) -> Vector{Bool}

直前の [`satisfiable!`](@ref) が保存した割り当てを返す(C++ 版準拠)。
直前の `satisfiable!` 呼び出しが `true` を返した後にのみ有効。
それ以外の場合の返り値は未定義(呼び出し前の初期値や古い割り当てが返る)。
"""
answer(ts::TwoSAT) = copy(ts._answer)
