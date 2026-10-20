# ==== 入力(TokenIO ワンライナー版)====
const _IN = Ref(""); const _POS = Ref(1)
input!() = (_IN[] = read(stdin, String); _POS[] = 1; nothing)
@inline function nextI(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; neg = false; @inbounds if p <= n && codeunit(s, p) == 0x2d; neg = true; p += 1; end; x = 0; @inbounds while p <= n; c = codeunit(s, p); (0x30 <= c <= 0x39) || break; x = 10x + Int(c - 0x30); p += 1; end; _POS[] = p; return neg ? -x : x; end
@inline function nextS(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; p > n && return SubString(s, 1, 0); q = p; @inbounds while q <= n && codeunit(s, q) > 0x20; q += 1; end; _POS[] = q; return SubString(s, p, thisind(s, q - 1)); end
nextF() = parse(Float64, nextS())
function nextC(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; p > n && return '\0'; c = s[p]; _POS[] = nextind(s, p); return c; end

# E - MinCostFlow
# https://atcoder.jp/contests/practice2/tasks/practice2_e
function (@main)(ARGS)
    input!()
    N = nextI(); K = nextI()
    A = Matrix{Int}(undef, N, N)
    for i in 1:N, j in 1:N
        A[i, j] = nextI()
    end

    BIG = 10^9
    # 頂点: 1 = s, 2 = t, 2+i = 行 i, 2+N+j = 列 j
    s, t = 1, 2
    g = MCFGraph{Int,Int}(2 + 2N)
    add_edge!(g, s, t, N * K, BIG)          # 使わない流量の逃げ道
    for i in 1:N
        add_edge!(g, s, 2 + i, K, 0)
    end
    for j in 1:N
        add_edge!(g, 2 + N + j, t, K, 0)
    end
    eid = Matrix{Int}(undef, N, N)
    for i in 1:N, j in 1:N
        eid[i, j] = add_edge!(g, 2 + i, 2 + N + j, 1, BIG - A[i, j])
    end

    _, cost = flow!(g, s, t, N * K)
    println(N * K * BIG - cost)
    for i in 1:N
        for j in 1:N
            print(get_edge(g, eid[i, j]).flow == 1 ? 'X' : '.')
        end
        println()
    end
end

# ==== ライブラリ: mincostflow.jl ====
# mincostflow.jl — 最小費用流(dual-primal + Dijkstra)。C++ 版 ACL mincostflow.hpp の移植。

"""
    MCFEdge{Cap,Cost}

`get_edge` / `edges` が返す辺の状態。フィールドは
`from`, `to`, `cap`(元の容量), `flow`(現在の流量), `cost`(単位流量あたりのコスト)。
"""
struct MCFEdge{Cap,Cost}
    from::Int
    to::Int
    cap::Cap
    flow::Cap
    cost::Cost
end

"""
    MCFGraph{Cap,Cost}(n::Integer)

`n` 頂点 0 辺の最小費用流グラフを作る。`Cap` は容量、`Cost` はコストの型
(いずれも整数型を想定)。頂点・辺 ID はすべて 1-indexed。

計算量は `flow!` / `slope!` 1 回あたり O(F (n + m) log (n + m))(F は流量)。
"""
struct MCFGraph{Cap,Cost}
    n::Int
    edges::Vector{MCFEdge{Cap,Cost}}
end

MCFGraph{Cap,Cost}(n::Integer) where {Cap,Cost} =
    MCFGraph{Cap,Cost}(Int(n), MCFEdge{Cap,Cost}[])

"""
    add_edge!(g::MCFGraph, from, to, cap, cost) -> Int

`from` から `to` へ容量 `cap`・コスト `cost` の辺を追加し、
辺 ID(1 始まり)を返す。`cap ≥ 0`, `cost ≥ 0` が前提。
"""
function add_edge!(g::MCFGraph{Cap,Cost}, from::Integer, to::Integer,
                   cap, cost) where {Cap,Cost}
    1 <= from <= g.n || throw(ArgumentError("from = $from が頂点範囲 1:$(g.n) 外です"))
    1 <= to <= g.n || throw(ArgumentError("to = $to が頂点範囲 1:$(g.n) 外です"))
    0 <= cap || throw(ArgumentError("cap = $cap が負です"))
    0 <= cost || throw(ArgumentError("cost = $cost が負です"))
    push!(g.edges, MCFEdge{Cap,Cost}(Int(from), Int(to), Cap(cap), zero(Cap), Cost(cost)))
    return length(g.edges)
end

"""
    get_edge(g::MCFGraph, i) -> MCFEdge

辺 ID `i` の現在の状態(容量・流量・コスト)を返す。
"""
function get_edge(g::MCFGraph, i::Integer)
    1 <= i <= length(g.edges) || throw(ArgumentError("i = $i が辺範囲 1:$(length(g.edges)) 外です"))
    return g.edges[i]
end

"""
    edges(g::MCFGraph) -> Vector{MCFEdge}

全辺の現在の状態を辺 ID 順に返す。
"""
edges(g::MCFGraph) = copy(g.edges)

# 残余グラフ(CSR 形式、並列配列)
struct _MCFCsr{Cap,Cost}
    start::Vector{Int}   # 頂点 v の辺は eto[start[v] : start[v+1]-1]
    eto::Vector{Int}
    erev::Vector{Int}
    ecap::Vector{Cap}
    ecost::Vector{Cost}
end

# (key, to) の最小ヒープ
@inline function _mcf_heappush!(h::Vector{Tuple{Cost,Int}}, x::Tuple{Cost,Int}) where {Cost}
    push!(h, x)
    i = length(h)
    @inbounds while i > 1
        p = i >> 1
        h[p][1] <= h[i][1] && break
        h[p], h[i] = h[i], h[p]
        i = p
    end
    return h
end

@inline function _mcf_heappop!(h::Vector{Tuple{Cost,Int}}) where {Cost}
    top = h[1]
    x = pop!(h)
    n = length(h)
    if n > 0
        @inbounds begin
            h[1] = x
            i = 1
            while true
                l = 2i
                l > n && break
                c = (l < n && h[l+1][1] < h[l][1]) ? l + 1 : l
                h[c][1] >= h[i][1] && break
                h[c], h[i] = h[i], h[c]
                i = c
            end
        end
    end
    return top
end

# Dijkstra(dual 変数付き)。dist・prev_e を更新し、t に到達できたら dual を更新して true
function _mcf_dual_ref!(csr::_MCFCsr{Cap,Cost}, n::Int, s::Int, t::Int,
                        dual::Vector{Cost}, dist::Vector{Cost},
                        prev_e::Vector{Int}, vis::Vector{Bool},
                        que_min::Vector{Int},
                        que::Vector{Tuple{Cost,Int}}) where {Cap,Cost}
    fill!(dist, typemax(Cost))
    fill!(vis, false)
    empty!(que_min)
    empty!(que)

    dist[s] = zero(Cost)
    push!(que_min, s)
    @inbounds while !isempty(que_min) || !isempty(que)
        v = if !isempty(que_min)
            pop!(que_min)
        else
            _mcf_heappop!(que)[2]
        end
        vis[v] && continue
        vis[v] = true
        v == t && break
        # dist[v] = shortest(s, v) + dual[s] - dual[v] >= 0
        dual_v = dual[v]
        dist_v = dist[v]
        for i in csr.start[v]:(csr.start[v+1]-1)
            csr.ecap[i] == 0 && continue
            to = csr.eto[i]
            cost = csr.ecost[i] - dual[to] + dual_v   # reduced cost >= 0
            if dist[to] - dist_v > cost
                dist_to = dist_v + cost
                dist[to] = dist_to
                prev_e[to] = csr.erev[i]
                if dist_to == dist_v
                    push!(que_min, to)
                else
                    _mcf_heappush!(que, (dist_to, to))
                end
            end
        end
    end
    vis[t] || return false

    @inbounds for v in 1:n
        vis[v] || continue
        dual[v] -= dist[t] - dist[v]
    end
    return true
end

"""
    slope!(g::MCFGraph, s, t)
    slope!(g::MCFGraph, s, t, flow_limit) -> Vector{Tuple{Cap,Cost}}

`s` から `t` へ流量を増やしたときの (流量, 最小コスト) の折れ線
(凸な区分線形関数の頂点列)を返す。最初の要素は `(0, 0)`。
グラフの状態(各辺の流量)を変更する。`s != t` が前提。
"""
slope!(g::MCFGraph{Cap,Cost}, s::Integer, t::Integer) where {Cap,Cost} =
    slope!(g, s, t, typemax(Cap))

function slope!(g::MCFGraph{Cap,Cost}, s::Integer, t::Integer, flow_limit) where {Cap,Cost}
    1 <= s <= g.n || throw(ArgumentError("s = $s が頂点範囲 1:$(g.n) 外です"))
    1 <= t <= g.n || throw(ArgumentError("t = $t が頂点範囲 1:$(g.n) 外です"))
    s != t || throw(ArgumentError("s と t は異なる頂点である必要があります (s = t = $s)"))
    n = g.n
    m = length(g.edges)
    limit = Cap(flow_limit)

    # 残余グラフを CSR 化(C++ 版と同じレイアウト)
    degree = zeros(Int, n)
    edge_idx = Vector{Int}(undef, m)   # 辺 i の順方向エントリの(頂点内)順序
    redge_idx = Vector{Int}(undef, m)
    for i in 1:m
        e = g.edges[i]
        edge_idx[i] = (degree[e.from] += 1)
        redge_idx[i] = (degree[e.to] += 1)
    end
    start = Vector{Int}(undef, n + 1)
    start[1] = 1
    for v in 1:n
        start[v+1] = start[v] + degree[v]
    end
    eto = Vector{Int}(undef, 2m)
    erev = Vector{Int}(undef, 2m)
    ecap = Vector{Cap}(undef, 2m)
    ecost = Vector{Cost}(undef, 2m)
    for i in 1:m
        e = g.edges[i]
        fi = start[e.from] + edge_idx[i] - 1
        ri = start[e.to] + redge_idx[i] - 1
        eto[fi] = e.to
        erev[fi] = ri
        ecap[fi] = e.cap - e.flow
        ecost[fi] = e.cost
        eto[ri] = e.from
        erev[ri] = fi
        ecap[ri] = e.flow
        ecost[ri] = -e.cost
        edge_idx[i] = fi   # 以後は絶対位置として使う
    end
    csr = _MCFCsr{Cap,Cost}(start, eto, erev, ecap, ecost)

    # dual-primal 本体
    dual = zeros(Cost, n)
    dist = Vector{Cost}(undef, n)
    prev_e = zeros(Int, n)
    vis = zeros(Bool, n)
    que_min = Int[]
    que = Tuple{Cost,Int}[]

    flow = zero(Cap)
    cost = zero(Cost)
    prev_cost_per_flow = Cost(-1)
    result = [(zero(Cap), zero(Cost))]
    while flow < limit
        _mcf_dual_ref!(csr, n, Int(s), Int(t), dual, dist, prev_e, vis, que_min, que) || break
        c = limit - flow
        v = Int(t)
        while v != s
            c = min(c, csr.ecap[csr.erev[prev_e[v]]])
            v = csr.eto[prev_e[v]]
        end
        v = Int(t)
        while v != s
            pe = prev_e[v]
            csr.ecap[pe] += c
            csr.ecap[csr.erev[pe]] -= c
            v = csr.eto[pe]
        end
        d = -dual[s]
        flow += c
        cost += c * d
        prev_cost_per_flow == d && pop!(result)
        push!(result, (flow, cost))
        prev_cost_per_flow = d
    end

    # 流量を辺リストに書き戻す
    for i in 1:m
        e = g.edges[i]
        g.edges[i] = MCFEdge{Cap,Cost}(e.from, e.to, e.cap, e.cap - ecap[edge_idx[i]], e.cost)
    end

    return result
end

"""
    flow!(g::MCFGraph, s, t)
    flow!(g::MCFGraph, s, t, flow_limit) -> (flow, cost)

`s` から `t` へ流せるだけ(または `flow_limit` に達するまで)流し、
(流量, その流量での最小コスト) を返す。`slope!` の最後の要素と等しい。
返り値は今回の呼び出しで**追加で**流せた分であり、過去の呼び出し分は含まない。
グラフの状態(各辺の流量)を変更する。`s != t` が前提。
"""
flow!(g::MCFGraph{Cap,Cost}, s::Integer, t::Integer) where {Cap,Cost} =
    flow!(g, s, t, typemax(Cap))

flow!(g::MCFGraph{Cap,Cost}, s::Integer, t::Integer, flow_limit) where {Cap,Cost} =
    last(slope!(g, s, t, flow_limit))
