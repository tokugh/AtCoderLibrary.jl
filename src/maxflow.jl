# Library: https://github.com/tokugh/AtCoderLibrary.jl
# maxflow.jl — 最大流(Dinic 法)。C++ 版 ACL maxflow.hpp の移植。

# 内部辺:to へ向かう辺。rev は g[to] 内の逆辺の位置、cap は残余容量
struct _MFEdge{Cap}
    to::Int
    rev::Int
    cap::Cap
end

"""
    MFGraph{Cap}(n::Integer)

`n` 頂点 0 辺の最大流グラフを作る。`Cap` は容量の型(整数型を想定)。
頂点・辺 ID はすべて 1-indexed。

計算量は `flow!` 1 回あたり O(n² m)(実用上ははるかに高速)。
"""
struct MFGraph{Cap}
    n::Int
    pos::Vector{Tuple{Int,Int}}      # 辺 ID -> (from, g[from] 内の位置)
    g::Vector{Vector{_MFEdge{Cap}}}
end

MFGraph{Cap}(n::Integer) where {Cap} =
    MFGraph{Cap}(Int(n), Tuple{Int,Int}[], [_MFEdge{Cap}[] for _ in 1:n])

"""
    MFEdge{Cap}

`get_edge` / `edges` が返す辺の状態。フィールドは
`from`, `to`, `cap`(元の容量), `flow`(現在の流量)。
"""
struct MFEdge{Cap}
    from::Int
    to::Int
    cap::Cap
    flow::Cap
end

"""
    add_edge!(g::MFGraph, from, to, cap) -> Int

`from` から `to` へ容量 `cap` の辺を追加し、辺 ID(1 始まり)を返す。
`from == to`(自己ループ)も許される。
"""
function add_edge!(g::MFGraph{Cap}, from::Integer, to::Integer, cap) where {Cap}
    1 <= from <= g.n || throw(ArgumentError("from = $from が頂点範囲 1:$(g.n) 外です"))
    1 <= to <= g.n || throw(ArgumentError("to = $to が頂点範囲 1:$(g.n) 外です"))
    0 <= cap || throw(ArgumentError("cap = $cap が負です"))
    push!(g.pos, (Int(from), length(g.g[from]) + 1))
    from_id = length(g.g[from]) + 1
    to_id = length(g.g[to]) + 1
    from == to && (to_id += 1)
    push!(g.g[from], _MFEdge{Cap}(Int(to), to_id, Cap(cap)))
    push!(g.g[to], _MFEdge{Cap}(Int(from), from_id, zero(Cap)))
    return length(g.pos)
end

"""
    get_edge(g::MFGraph, i) -> MFEdge

辺 ID `i` の現在の状態(容量と流量)を返す。
"""
function get_edge(g::MFGraph{Cap}, i::Integer) where {Cap}
    1 <= i <= length(g.pos) || throw(ArgumentError("i = $i が辺範囲 1:$(length(g.pos)) 外です"))
    from, idx = g.pos[i]
    e = g.g[from][idx]
    re = g.g[e.to][e.rev]
    return MFEdge{Cap}(from, e.to, e.cap + re.cap, re.cap)
end

"""
    edges(g::MFGraph) -> Vector{MFEdge}

全辺の現在の状態を辺 ID 順に返す。
"""
edges(g::MFGraph) = [get_edge(g, i) for i in 1:length(g.pos)]

"""
    change_edge!(g::MFGraph, i, new_cap, new_flow)

辺 ID `i` の容量と流量を `new_cap`, `new_flow` に変更する。
`0 ≤ new_flow ≤ new_cap` が前提。他の辺の容量・流量は変化しない。
"""
function change_edge!(g::MFGraph{Cap}, i::Integer, new_cap, new_flow) where {Cap}
    1 <= i <= length(g.pos) || throw(ArgumentError("i = $i が辺範囲 1:$(length(g.pos)) 外です"))
    0 <= new_flow <= new_cap ||
        throw(ArgumentError("0 ≤ new_flow ≤ new_cap が必要です (new_flow = $new_flow, new_cap = $new_cap)"))
    from, idx = g.pos[i]
    e = g.g[from][idx]
    g.g[from][idx] = _MFEdge{Cap}(e.to, e.rev, Cap(new_cap) - Cap(new_flow))
    re = g.g[e.to][e.rev]
    g.g[e.to][e.rev] = _MFEdge{Cap}(re.to, re.rev, Cap(new_flow))
    return g
end

function _mf_bfs!(g::MFGraph{Cap}, level::Vector{Int}, que::Vector{Int},
                  s::Int, t::Int) where {Cap}
    fill!(level, -1)
    level[s] = 0
    empty!(que)
    push!(que, s)
    qi = 1
    while qi <= length(que)
        v = que[qi]
        qi += 1
        for e in g.g[v]
            (e.cap == 0 || level[e.to] >= 0) && continue
            level[e.to] = level[v] + 1
            e.to == t && return nothing
            push!(que, e.to)
        end
    end
    return nothing
end

# t から s へ向かって逆向きに増加路を探す(C++ 版と同じ構造)
function _mf_dfs!(g::MFGraph{Cap}, level::Vector{Int}, iter::Vector{Int},
                  s::Int, v::Int, up::Cap) where {Cap}
    v == s && return up
    res = zero(Cap)
    level_v = level[v]
    gv = g.g[v]
    while iter[v] <= length(gv)
        i = iter[v]
        e = gv[i]
        if level_v <= level[e.to] || g.g[e.to][e.rev].cap == 0
            iter[v] += 1
            continue
        end
        d = _mf_dfs!(g, level, iter, s, e.to, min(up - res, g.g[e.to][e.rev].cap))
        if d <= 0
            iter[v] += 1
            continue
        end
        gv[i] = _MFEdge{Cap}(e.to, e.rev, e.cap + d)
        re = g.g[e.to][e.rev]
        g.g[e.to][e.rev] = _MFEdge{Cap}(re.to, re.rev, re.cap - d)
        res += d
        res == up && return res
        iter[v] += 1
    end
    level[v] = g.n
    return res
end

"""
    flow!(g::MFGraph, s, t)
    flow!(g::MFGraph, s, t, flow_limit)

`s` から `t` へ流せるだけ(または追加流量が `flow_limit` に達するまで)流し、
**追加で**流せた流量を返す。複数回呼ぶことができ、グラフの状態
(各辺の流量)を変更する。`s != t` が前提。
"""
flow!(g::MFGraph{Cap}, s::Integer, t::Integer) where {Cap} =
    flow!(g, s, t, typemax(Cap))

function flow!(g::MFGraph{Cap}, s::Integer, t::Integer, flow_limit) where {Cap}
    1 <= s <= g.n || throw(ArgumentError("s = $s が頂点範囲 1:$(g.n) 外です"))
    1 <= t <= g.n || throw(ArgumentError("t = $t が頂点範囲 1:$(g.n) 外です"))
    s != t || throw(ArgumentError("s と t は異なる頂点である必要があります (s = t = $s)"))
    limit = Cap(flow_limit)
    level = Vector{Int}(undef, g.n)
    iter = Vector{Int}(undef, g.n)
    que = Int[]
    fl = zero(Cap)
    while fl < limit
        _mf_bfs!(g, level, que, Int(s), Int(t))
        level[t] == -1 && break
        fill!(iter, 1)
        f = _mf_dfs!(g, level, iter, Int(s), Int(t), limit - fl)
        f == 0 && break
        fl += f
    end
    return fl
end

"""
    min_cut(g::MFGraph, s) -> Vector{Bool}

残余グラフで `s` から到達可能な頂点を `true` とするベクトルを返す。
`flow!(g, s, t)` を流し切った直後に呼ぶと、返り値は最小カットの
`s` 側集合になる。
"""
function min_cut(g::MFGraph, s::Integer)
    1 <= s <= g.n || throw(ArgumentError("s = $s が頂点範囲 1:$(g.n) 外です"))
    visited = zeros(Bool, g.n)
    que = Int[Int(s)]
    qi = 1
    while qi <= length(que)
        p = que[qi]
        qi += 1
        visited[p] = true
        for e in g.g[p]
            if e.cap != 0 && !visited[e.to]
                visited[e.to] = true
                push!(que, e.to)
            end
        end
    end
    return visited
end
