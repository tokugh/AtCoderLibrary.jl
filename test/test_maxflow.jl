using Test
using Random

# ランダムグラフの最大流を全カット列挙で検算するヘルパー
function mf_brute_min_cut(n, edge_list, s, t)
    best = typemax(Int)
    for mask in 0:(2^n - 1)
        (mask >> (s - 1)) & 1 == 1 || continue
        (mask >> (t - 1)) & 1 == 0 || continue
        cut = 0
        for (from, to, cap) in edge_list
            if (mask >> (from - 1)) & 1 == 1 && (mask >> (to - 1)) & 1 == 0
                cut += cap
            end
        end
        best = min(best, cut)
    end
    return best
end

@testset "maxflow" begin
    @testset "simple" begin
        g = MFGraph{Int}(4)
        @test add_edge!(g, 1, 2, 1) == 1
        @test add_edge!(g, 1, 3, 1) == 2
        @test add_edge!(g, 2, 4, 1) == 3
        @test add_edge!(g, 3, 4, 1) == 4
        @test add_edge!(g, 2, 3, 1) == 5
        @test flow!(g, 1, 4) == 2

        e = get_edge(g, 1)
        @test (e.from, e.to, e.cap, e.flow) == (1, 2, 1, 1)
        e = get_edge(g, 2)
        @test (e.from, e.to, e.cap, e.flow) == (1, 3, 1, 1)
        e = get_edge(g, 3)
        @test (e.from, e.to, e.cap, e.flow) == (2, 4, 1, 1)
        e = get_edge(g, 4)
        @test (e.from, e.to, e.cap, e.flow) == (3, 4, 1, 1)
        e = get_edge(g, 5)
        @test (e.from, e.to, e.cap, e.flow) == (2, 3, 1, 0)
        @test length(edges(g)) == 5

        @test min_cut(g, 1) == [true, false, false, false]
    end

    @testset "not_simple(多重辺・自己ループ)" begin
        g = MFGraph{Int}(2)
        add_edge!(g, 1, 2, 1)
        add_edge!(g, 1, 2, 2)
        add_edge!(g, 1, 2, 3)
        add_edge!(g, 1, 2, 4)
        add_edge!(g, 1, 2, 5)
        add_edge!(g, 1, 1, 6)
        add_edge!(g, 2, 1, 7)
        @test flow!(g, 1, 2) == 15
        e = get_edge(g, 1)
        @test (e.cap, e.flow) == (1, 1)
        e = get_edge(g, 6)   # 自己ループには流れない
        @test (e.cap, e.flow) == (6, 0)
    end

    @testset "cut" begin
        g = MFGraph{Int}(3)
        add_edge!(g, 1, 2, 2)
        add_edge!(g, 2, 3, 1)
        @test flow!(g, 1, 3) == 1
        e = get_edge(g, 1)
        @test (e.cap, e.flow) == (2, 1)
        @test min_cut(g, 1) == [true, true, false]
    end

    @testset "self_loop" begin
        g = MFGraph{Int}(3)
        add_edge!(g, 1, 1, 100)
        e = get_edge(g, 1)
        @test (e.from, e.to, e.cap, e.flow) == (1, 1, 100, 0)
    end

    @testset "flow_limit と再呼び出し" begin
        g = MFGraph{Int}(4)
        add_edge!(g, 1, 2, 1)
        add_edge!(g, 1, 3, 1)
        add_edge!(g, 2, 4, 1)
        add_edge!(g, 3, 4, 1)
        @test flow!(g, 1, 4, 1) == 1
        @test flow!(g, 1, 4) == 1      # 追加で流せる量
        @test flow!(g, 1, 4) == 0
    end

    @testset "change_edge!" begin
        g = MFGraph{Int}(2)
        id = add_edge!(g, 1, 2, 1)
        @test flow!(g, 1, 2) == 1
        change_edge!(g, id, 100, 10)
        e = get_edge(g, id)
        @test (e.cap, e.flow) == (100, 10)
        @test flow!(g, 1, 2) == 90
    end

    @testset "invalid" begin
        g = MFGraph{Int}(2)
        @test_throws ArgumentError add_edge!(g, 0, 2, 1)
        @test_throws ArgumentError add_edge!(g, 1, 3, 1)
        @test_throws ArgumentError add_edge!(g, 1, 2, -1)
        @test_throws ArgumentError flow!(g, 1, 1)
    end

    @testset "stress(全カット列挙との突き合わせ)" begin
        rng = MersenneTwister(20260711)
        for _ in 1:300
            n = rand(rng, 2:8)
            m = rand(rng, 0:15)
            s = rand(rng, 1:n)
            t = rand(rng, 1:n)
            while t == s
                t = rand(rng, 1:n)
            end
            g = MFGraph{Int}(n)
            edge_list = Tuple{Int,Int,Int}[]
            for _ in 1:m
                u, v = rand(rng, 1:n), rand(rng, 1:n)
                c = rand(rng, 0:10)
                add_edge!(g, u, v, c)
                push!(edge_list, (u, v, c))
            end
            f = flow!(g, s, t)
            @test f == mf_brute_min_cut(n, edge_list, s, t)

            # 流量保存則と min_cut の整合
            netout = zeros(Int, n)
            for e in edges(g)
                @test 0 <= e.flow <= e.cap
                netout[e.from] += e.flow
                netout[e.to] -= e.flow
            end
            for v in 1:n
                if v == s
                    @test netout[v] == f
                elseif v == t
                    @test netout[v] == -f
                else
                    @test netout[v] == 0
                end
            end
            cutside = min_cut(g, s)
            @test cutside[s] && !cutside[t]
            cutcap = sum((cap for (u, v, cap) in edge_list
                          if cutside[u] && !cutside[v]); init = 0)
            @test cutcap == f
        end
    end
end
