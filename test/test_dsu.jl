using Test
using Random
using AtCoderLibrary

# ナイーブな Union-Find(グループを Set の配列で保持)
struct DSUNaive
    grp::Vector{Int}  # grp[i] = 頂点 i のグループ id
end
dsu_naive(n) = DSUNaive(collect(1:n))
function dsu_naive_merge!(d::DSUNaive, a, b)
    ga, gb = d.grp[a], d.grp[b]
    for i in eachindex(d.grp)
        d.grp[i] == gb && (d.grp[i] = ga)
    end
end
dsu_naive_same(d::DSUNaive, a, b) = d.grp[a] == d.grp[b]
dsu_naive_size(d::DSUNaive, a) = count(==(d.grp[a]), d.grp)
dsu_naive_groups(d::DSUNaive) =
    sort!([sort!(findall(==(g), d.grp)) for g in unique(d.grp)]; by = first)

@testset "dsu" begin
    rng = MersenneTwister(20260711)

    @testset "基本操作" begin
        d = DSU(4)
        @test length(d) == 4
        @test !same(d, 1, 2)
        x = merge!(d, 1, 2)
        @test x == leader(d, 1) == leader(d, 2)
        @test same(d, 1, 2)
        @test group_size(d, 1) == 2
        @test group_size(d, 3) == 1
        @test merge!(d, 1, 2) == x  # 既に同一グループなら代表を返すだけ
        @test groups(d) == [[1, 2], [3], [4]]
        merge!(d, 3, 4)
        merge!(d, 2, 3)
        @test groups(d) == [[1, 2, 3, 4]]
        @test group_size(d, 4) == 4
    end

    @testset "頂点 1 個・境界" begin
        d = DSU(1)
        @test leader(d, 1) == 1
        @test merge!(d, 1, 1) == 1
        @test groups(d) == [[1]]
        @test_throws BoundsError leader(d, 0)
        @test_throws BoundsError leader(d, 2)
        @test_throws BoundsError merge!(d, 1, 2)
        @test_throws BoundsError same(d, 0, 1)
    end

    @testset "ランダム比較" begin
        for trial in 1:20
            n = rand(rng, 1:50)
            d = DSU(n)
            nv = dsu_naive(n)
            for _ in 1:100
                a, b = rand(rng, 1:n), rand(rng, 1:n)
                if rand(rng, Bool)
                    r = merge!(d, a, b)
                    dsu_naive_merge!(nv, a, b)
                    @test r == leader(d, a) == leader(d, b)
                else
                    @test same(d, a, b) == dsu_naive_same(nv, a, b)
                end
                @test group_size(d, a) == dsu_naive_size(nv, a)
            end
            @test groups(d) == dsu_naive_groups(nv)
        end
    end

    @testset "直線グラフ(経路圧縮の健全性)" begin
        n = 10_000
        d = DSU(n)
        for i in 1:(n-1)
            merge!(d, i, i + 1)
        end
        @test group_size(d, 1) == n
        @test all(leader(d, i) == leader(d, 1) for i in 1:n)
        @test length(groups(d)) == 1
    end
end
