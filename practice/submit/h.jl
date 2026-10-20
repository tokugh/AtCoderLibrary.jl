# ==== 入力(TokenIO ワンライナー版)====
const _IN = Ref(""); const _POS = Ref(1)
input!() = (_IN[] = read(stdin, String); _POS[] = 1; nothing)
@inline function nextI(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; neg = false; @inbounds if p <= n && codeunit(s, p) == 0x2d; neg = true; p += 1; end; x = 0; @inbounds while p <= n; c = codeunit(s, p); (0x30 <= c <= 0x39) || break; x = 10x + Int(c - 0x30); p += 1; end; _POS[] = p; return neg ? -x : x; end
@inline function nextS(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; p > n && return SubString(s, 1, 0); q = p; @inbounds while q <= n && codeunit(s, q) > 0x20; q += 1; end; _POS[] = q; return SubString(s, p, thisind(s, q - 1)); end
nextF() = parse(Float64, nextS())
function nextC(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; p > n && return '\0'; c = s[p]; _POS[] = nextind(s, p); return c; end

# H - Two SAT
# https://atcoder.jp/contests/practice2/tasks/practice2_h
function (@main)(ARGS)
    input!()
    N = nextI(); D = nextI()
    X = Vector{Int}(undef, N)
    Y = Vector{Int}(undef, N)
    for i in 1:N
        X[i] = nextI()
        Y[i] = nextI()
    end

    # x_i = true ⟺ 旗 i を X[i] に置く
    ts = TwoSAT(N)
    for i in 1:N, j in (i+1):N
        for (fi, ci) in ((true, X[i]), (false, Y[i]))
            for (fj, cj) in ((true, X[j]), (false, Y[j]))
                if abs(ci - cj) < D
                    # (x_i = fi) かつ (x_j = fj) は禁止
                    add_clause!(ts, i, !fi, j, !fj)
                end
            end
        end
    end

    if satisfiable!(ts)
        ans = answer(ts)
        println("Yes")
        for i in 1:N
            println(ans[i] ? X[i] : Y[i])
        end
    else
        println("No")
    end
end

# ==== ライブラリ: scc.jl ====
# Library: https://github.com/tokugh/AtCoderLibrary.jl
# scc.jl — 強連結成分分解 (C++ 版 atcoder/scc.hpp, internal_scc.hpp の移植)

# 内部: CSR 形式の隣接リスト。頂点 v の隣接は elist[start[v] : start[v+1]-1]
struct _SccCSR
    start::Vector{Int}
    elist::Vector{Int}
end

function _SccCSR(n::Int, edges::Vector{Tuple{Int,Int}})
    start = Vector{Int}(undef, n + 1)
    cnt = zeros(Int, n)
    for (from, _) in edges
        cnt[from] += 1
    end
    start[1] = 1
    for v in 1:n
        start[v+1] = start[v] + cnt[v]
    end
    counter = copy(start)
    elist = Vector{Int}(undef, length(edges))
    for (from, to) in edges
        elist[counter[from]] = to
        counter[from] += 1
    end
    _SccCSR(start, elist)
end

"""
    SCCGraph(n::Integer)

`n` 頂点 0 辺の有向グラフ。[`add_edge!`](@ref) で辺を追加し、
[`scc`](@ref) で強連結成分分解する。頂点は 1-indexed(`1:n`)。
"""
struct SCCGraph
    n::Int
    edges::Vector{Tuple{Int,Int}}
end

SCCGraph(n::Integer) = SCCGraph(Int(n), Tuple{Int,Int}[])

"""
    add_edge!(g::SCCGraph, from::Integer, to::Integer) -> g

有向辺 `from → to` を追加する。`from`, `to` は `1:n` の範囲であること。
"""
function add_edge!(g::SCCGraph, from::Integer, to::Integer)
    1 <= from <= g.n || throw(ArgumentError("from = $from が頂点範囲 1:$(g.n) 外です"))
    1 <= to <= g.n || throw(ArgumentError("to = $to が頂点範囲 1:$(g.n) 外です"))
    push!(g.edges, (Int(from), Int(to)))
    g
end

# 内部: (成分数, 各頂点の成分 id) を返す。id は 1-indexed かつトポロジカル順
# (u → v の辺があれば ids[u] ≤ ids[v])。
# C++ 版の再帰 dfs (Tarjan) を明示スタックで反復化してある。
function _scc_ids(g::SCCGraph)
    n = g.n
    csr = _SccCSR(n, g.edges)
    now_ord = 0
    group_num = 0
    visited = Int[]
    sizehint!(visited, n)
    low = zeros(Int, n)
    ord = fill(-1, n)
    ids = zeros(Int, n)
    stack = Tuple{Int,Int}[]   # (頂点, 次に見る辺の elist インデックス)
    sizehint!(stack, n)
    for root in 1:n
        ord[root] == -1 || continue
        ord[root] = low[root] = now_ord
        now_ord += 1
        push!(visited, root)
        push!(stack, (root, csr.start[root]))
        while !isempty(stack)
            v, i = stack[end]
            if i < csr.start[v+1]
                stack[end] = (v, i + 1)
                to = csr.elist[i]
                if ord[to] == -1
                    ord[to] = low[to] = now_ord
                    now_ord += 1
                    push!(visited, to)
                    push!(stack, (to, csr.start[to]))
                else
                    low[v] = min(low[v], ord[to])
                end
            else
                pop!(stack)
                if low[v] == ord[v]
                    while true
                        u = pop!(visited)
                        ord[u] = n   # 処理済みマーク(以後 low に影響しない)
                        ids[u] = group_num
                        u == v && break
                    end
                    group_num += 1
                end
                if !isempty(stack)
                    p = stack[end][1]
                    low[p] = min(low[p], low[v])
                end
            end
        end
    end
    for v in 1:n
        ids[v] = group_num - ids[v]
    end
    (group_num, ids)
end

"""
    scc(g::SCCGraph) -> Vector{Vector{Int}}

強連結成分分解。「同一成分に属する ⟺ 相互に到達可能」となるように頂点を分割し、
成分のリストを返す。成分はトポロジカル順(頂点 u から v に到達できるとき、
u の成分は v の成分より前か同一)に並び、各成分内の頂点は昇順。

計算量: 頂点数 n、辺数 m に対して O(n + m)。
"""
function scc(g::SCCGraph)
    group_num, ids = _scc_ids(g)
    counts = zeros(Int, group_num)
    for x in ids
        counts[x] += 1
    end
    groups = [Int[] for _ in 1:group_num]
    for c in 1:group_num
        sizehint!(groups[c], counts[c])
    end
    for v in 1:g.n
        push!(groups[ids[v]], v)
    end
    groups
end

# ==== ライブラリ: twosat.jl ====
# Library: https://github.com/tokugh/AtCoderLibrary.jl
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
