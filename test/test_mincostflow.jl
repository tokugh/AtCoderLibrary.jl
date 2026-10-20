using Test
using Random

# 素朴な逐次最短路(Bellman-Ford)による最小費用流。コスト非負なので結果は一致する
function mcf_naive_flow(n, edge_list, s, t, flow_limit)
    m = length(edge_list)
    # 残余:各辺 i について fwd cap[i], bwd flow[i]
    flow_on = zeros(Int, m)
    total_flow = 0
    total_cost = 0
    while total_flow < flow_limit
        # Bellman-Ford(残余グラフ、逆辺はコスト -cost)
        dist = fill(typemax(Int) ÷ 4, n)
        prev_arc = fill((0, false), n)   # (辺 ID, 逆辺か)
        dist[s] = 0
        for _ in 1:n
            updated = false
            for i in 1:m
                (u, v, cap, cost) = edge_list[i]
                if cap - flow_on[i] > 0 && dist[u] + cost < dist[v]
                    dist[v] = dist[u] + cost
                    prev_arc[v] = (i, false)
                    updated = true
                end
                if flow_on[i] > 0 && dist[v] - cost < dist[u]
                    dist[u] = dist[v] - cost
                    prev_arc[u] = (i, true)
                    updated = true
                end
            end
            updated || break
        end
        dist[t] >= typemax(Int) ÷ 4 && break
        # ボトルネック
        c = flow_limit - total_flow
        v = t
        while v != s
            (i, isrev) = prev_arc[v]
            (u2, v2, cap, _) = edge_list[i]
            if isrev
                c = min(c, flow_on[i])
                v = v2
            else
                c = min(c, cap - flow_on[i])
                v = u2
            end
        end
        v = t
        while v != s
            (i, isrev) = prev_arc[v]
            (u2, v2, _, _) = edge_list[i]
            if isrev
                flow_on[i] -= c
                v = v2
            else
                flow_on[i] += c
                v = u2
            end
        end
        total_flow += c
        total_cost += c * dist[t]
    end
    return (total_flow, total_cost)
end

@testset "mincostflow" begin
    @testset "simple" begin
        g = MCFGraph{Int,Int}(4)
        @test add_edge!(g, 1, 2, 1, 1) == 1
        @test add_edge!(g, 1, 3, 1, 1) == 2
        @test add_edge!(g, 2, 4, 1, 1) == 3
        @test add_edge!(g, 3, 4, 1, 1) == 4
        @test add_edge!(g, 2, 3, 1, 1) == 5
        @test slope!(g, 1, 4, 10) == [(0, 0), (2, 4)]

        e = get_edge(g, 1)
        @test (e.from, e.to, e.cap, e.flow, e.cost) == (1, 2, 1, 1, 1)
        e = get_edge(g, 3)
        @test (e.from, e.to, e.cap, e.flow, e.cost) == (2, 4, 1, 1, 1)
        e = get_edge(g, 5)
        @test (e.from, e.to, e.cap, e.flow, e.cost) == (2, 3, 1, 0, 1)
        @test length(edges(g)) == 5
    end

    @testset "usage" begin
        g = MCFGraph{Int,Int}(2)
        add_edge!(g, 1, 2, 1, 2)
        @test flow!(g, 1, 2) == (1, 2)

        g = MCFGraph{Int,Int}(2)
        add_edge!(g, 1, 2, 1, 2)
        @test slope!(g, 1, 2) == [(0, 0), (1, 2)]
    end

    @testset "same_cost_paths(同コスト経路の統合)" begin
        g = MCFGraph{Int,Int}(3)
        @test add_edge!(g, 1, 2, 1, 1) == 1
        @test add_edge!(g, 2, 3, 1, 0) == 2
        @test add_edge!(g, 1, 3, 2, 1) == 3
        @test slope!(g, 1, 3) == [(0, 0), (3, 3)]
    end

    @testset "only_one_nonzero_cost_edge" begin
        g = MCFGraph{Int,Int}(3)
        add_edge!(g, 1, 2, 1, 1)
        add_edge!(g, 2, 3, 1, 0)
        @test slope!(g, 1, 3) == [(0, 0), (1, 1)]
    end

    @testset "invalid" begin
        g = MCFGraph{Int,Int}(2)
        @test_throws ArgumentError add_edge!(g, 0, 2, 1, 1)
        @test_throws ArgumentError add_edge!(g, 1, 2, -1, 1)
        @test_throws ArgumentError add_edge!(g, 1, 2, 1, -1)
        @test_throws ArgumentError slope!(g, 1, 1)
    end

    @testset "stress(Bellman-Ford SSP との突き合わせ)" begin
        rng = MersenneTwister(20260711)
        for _ in 1:200
            n = rand(rng, 2:6)
            m = rand(rng, 0:12)
            s = rand(rng, 1:n)
            t = rand(rng, 1:n)
            while t == s
                t = rand(rng, 1:n)
            end
            limit = rand(rng, (5, typemax(Int)))
            g = MCFGraph{Int,Int}(n)
            edge_list = Tuple{Int,Int,Int,Int}[]
            for _ in 1:m
                u, v = rand(rng, 1:n), rand(rng, 1:n)
                u == v && continue   # 自己ループは意味がないので除外
                cap = rand(rng, 0:8)
                cost = rand(rng, 0:8)
                add_edge!(g, u, v, cap, cost)
                push!(edge_list, (u, v, cap, cost))
            end
            result = slope!(g, s, t, limit)
            expected = mcf_naive_flow(n, edge_list, s, t, limit)
            @test last(result) == expected

            # slope! の性質:始点 (0,0)、流量狭義単調増加、傾き狭義単調増加(凸性)
            @test result[1] == (0, 0)
            for k in 2:length(result)
                @test result[k][1] > result[k-1][1]
            end
            slopes = [(result[k][2] - result[k-1][2]) // (result[k][1] - result[k-1][1])
                      for k in 2:length(result)]
            @test all(slopes[k] < slopes[k+1] for k in 1:length(slopes)-1)

            # 辺の流量の整合:流量保存則とコスト一致
            netout = zeros(Int, n)
            realcost = 0
            for e in edges(g)
                @test 0 <= e.flow <= e.cap
                netout[e.from] += e.flow
                netout[e.to] -= e.flow
                realcost += e.flow * e.cost
            end
            (f, c) = last(result)
            for v in 1:n
                if v == s
                    @test netout[v] == f
                elseif v == t
                    @test netout[v] == -f
                else
                    @test netout[v] == 0
                end
            end
            @test realcost == c
        end
    end
end
