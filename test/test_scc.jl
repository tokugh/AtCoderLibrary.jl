using Test
using Random

# ナイーブな到達可能性行列 (Floyd–Warshall 流)
function scc_test_reach_matrix(n, edges)
    reach = falses(n, n)
    for v in 1:n
        reach[v, v] = true
    end
    for (u, v) in edges
        reach[u, v] = true
    end
    for k in 1:n, i in 1:n, j in 1:n
        reach[i, j] |= reach[i, k] && reach[k, j]
    end
    reach
end

@testset "SCCGraph" begin
    @testset "空グラフ・単一頂点" begin
        @test scc(SCCGraph(0)) == Vector{Int}[]
        @test scc(SCCGraph(1)) == [[1]]
        g = SCCGraph(1)
        add_edge!(g, 1, 1)   # 自己ループ
        @test scc(g) == [[1]]
    end

    @testset "固定ケース" begin
        # DAG: 1 → 2 → 3
        g = SCCGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        @test scc(g) == [[1], [2], [3]]

        # 単一サイクル
        g = SCCGraph(3)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 1)
        @test scc(g) == [[1, 2, 3]]

        # 多重辺
        g = SCCGraph(2)
        add_edge!(g, 1, 2)
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 1)
        @test scc(g) == [[1, 2]]

        # ACL Practice Contest G のサンプル (0-indexed 入力を +1 して読み込み)
        g = SCCGraph(6)
        for (u, v) in [(1, 4), (5, 2), (3, 0), (5, 5), (4, 1), (0, 3), (4, 2)]
            add_edge!(g, u + 1, v + 1)
        end
        @test scc(g) == [[6], [2, 5], [3], [1, 4]]

        # 範囲チェック
        g = SCCGraph(2)
        @test_throws ArgumentError add_edge!(g, 0, 1)
        @test_throws ArgumentError add_edge!(g, 1, 3)
    end

    @testset "ランダム検証" begin
        rng = MersenneTwister(20260711)
        for _ in 1:300
            n = rand(rng, 1:10)
            m = rand(rng, 0:20)
            edges = [(rand(rng, 1:n), rand(rng, 1:n)) for _ in 1:m]
            g = SCCGraph(n)
            for (u, v) in edges
                add_edge!(g, u, v)
            end
            gs = scc(g)

            # (3) 全頂点がちょうど 1 回現れる
            @test sort(reduce(vcat, gs; init = Int[])) == collect(1:n)

            reach = scc_test_reach_matrix(n, edges)
            comp = zeros(Int, n)
            for (ci, grp) in enumerate(gs), v in grp
                comp[v] = ci
            end

            # (1) 同一成分 ⟺ 相互到達可能
            @test all(
                (comp[u] == comp[v]) == (reach[u, v] && reach[v, u])
                for u in 1:n, v in 1:n
            )

            # (2) 成分間がトポロジカル順
            @test all(comp[u] <= comp[v] for (u, v) in edges)
        end
    end

    @testset "深いグラフ(明示スタック反復化の検証)" begin
        n = 200_000
        g = SCCGraph(n)
        for v in 1:n-1
            add_edge!(g, v, v + 1)
        end
        add_edge!(g, n, 1)
        @test scc(g) == [collect(1:n)]

        # 一本道 (サイクルなし) は n 個の単元成分がトポロジカル順に並ぶ
        g = SCCGraph(n)
        for v in 1:n-1
            add_edge!(g, v, v + 1)
        end
        gs = scc(g)
        @test length(gs) == n
        @test all(gs[v] == [v] for v in 1:n)
    end
end
