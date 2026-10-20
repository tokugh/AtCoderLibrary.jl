using Test, Random
using AtCoderLibrary

@testset "FenwickTree" begin
    fen_rng = MersenneTwister(20260712)

    @testset "加法群(デフォルト)vs ナイーブ" begin
        for _ in 1:50
            n = rand(fen_rng, 1:30)
            a = rand(fen_rng, -100:100, n)
            ft = FenwickTree(copy(a))
            for _ in 1:50
                c = rand(fen_rng, 1:4)
                if c == 1
                    i = rand(fen_rng, 1:n)
                    x = rand(fen_rng, -100:100)
                    add!(ft, i, x)
                    a[i] += x
                elseif c == 2
                    i = rand(fen_rng, 1:n)
                    x = rand(fen_rng, -100:100)
                    ft[i] = x
                    a[i] = x
                elseif c == 3
                    i = rand(fen_rng, 1:n)
                    @test ft[i] == a[i]
                else
                    l = rand(fen_rng, 1:n)
                    r = rand(fen_rng, 1:n)
                    @test sum(ft, l:r) == (l <= r ? sum(a[l:r]) : 0)
                end
            end
            @test sum(ft) == sum(a)
            @test prefix(ft, 0) == 0
        end
    end

    @testset "min モノイド(逆元なし)= prefix のみ" begin
        mft = FenwickTree(min, typemax(Int), nothing, [3, 1, 4, 1, 5])
        @test prefix(mft, 3) == 1
        @test prefix(mft, 1) == 3
        @test prefix(mft, 0) == typemax(Int)
        @test prefix(mft, 5) == 1
        mult!(mft, 1, 0)
        @test prefix(mft, 1) == 0
        # 逆元がない → 区間クエリ系はエラー(設計ノート §4)
        @test_throws ArgumentError prod(mft, 1:3)
        @test_throws ArgumentError mft[2]
        @test_throws ArgumentError set!(mft, 2, 100)
        # add! は加法群専用なのでメソッド自体が存在しない
        @test_throws MethodError add!(mft, 1, 1)
    end

    @testset "3 引数形(invop 省略)= 可換モノイド" begin
        # max モノイド: point chmax + prefix max
        ft = FenwickTree(max, typemin(Int), [3, 1, 4, 1, 5])
        @test prefix(ft, 3) == 4
        @test prefix(ft, 0) == typemin(Int)
        mult!(ft, 2, 10)                 # chmax
        @test prefix(ft, 3) == 10
        @test prefix(ft, 1) == 3
        @test_throws ArgumentError prod(ft, 1:3)
        @test_throws ArgumentError ft[2]
        @test_throws ArgumentError set!(ft, 2, 100)

        # n::Integer 版が 4 引数 nothing 版と等価であること
        ft2 = FenwickTree(max, typemin(Int), 4)
        ft3 = FenwickTree(max, typemin(Int), nothing, 4)
        @test typeof(ft2) == typeof(ft3)
        for (i, x) in ((1, 5), (3, 2), (4, 7), (1, -1))
            mult!(ft2, i, x)
            mult!(ft3, i, x)
        end
        @test all(prefix(ft2, r) == prefix(ft3, r) for r in 0:4)

        # 3 引数の + は「逆元なしの和」: prefix は動くが区間クエリはエラー
        fts = FenwickTree(+, 0, [1, 2, 3])
        @test prefix(fts, 3) == 6
        @test_throws ArgumentError sum(fts, 1:2)
    end

    @testset "{S} 明示形: Union{Missing,Int} の max モノイド" begin
        mop(a, b) = ismissing(a) ? b : ismissing(b) ? a : max(a, b)
        ft = FenwickTree{Union{Missing,Int}}(mop, missing, 5)
        @test prefix(ft, 5) === missing
        mult!(ft, 2, 7)
        mult!(ft, 4, 3)
        @test prefix(ft, 1) === missing
        @test prefix(ft, 3) == 7
        @test prefix(ft, 5) == 7
        @test_throws ArgumentError prod(ft, 1:2)
        # ベクタ版(O(n) 構築の畳み上げが missing 込みで正しいこと)
        ft2 = FenwickTree{Union{Missing,Int}}(mop, missing, Union{Missing,Int}[3, missing, 4])
        @test prefix(ft2, 2) == 3
        @test prefix(ft2, 3) == 4
        # {S} 明示と無印(S = typeof(e))の等価性
        @test typeof(FenwickTree{Int}(max, typemin(Int), 4)) ==
              typeof(FenwickTree(max, typemin(Int), 4))
    end

    @testset "乗法群(ModInt)" begin
        M = ModInt998244353
        ft = FenwickTree(*, one(M), inv, M.([2, 3, 5, 7]))
        @test val(prefix(ft, 4)) == 210
        @test val(prod(ft, 2:3)) == 15
        @test val(prod(ft, 2:1)) == 1   # 空区間 = 単位元
        set!(ft, 2, M(4))
        @test val(prod(ft, 1:2)) == 8
        mult!(ft, 3, M(2))
        @test val(ft[3]) == 10
    end

    @testset "境界" begin
        ft = FenwickTree{Int}(5)
        @test sum(ft, 1:5) == 0
        @test length(ft) == 5
        @test_throws BoundsError prefix(ft, 6)
        @test_throws BoundsError prefix(ft, -1)
        @test_throws BoundsError add!(ft, 0, 1)
        @test_throws BoundsError add!(ft, 6, 1)
        ft0 = FenwickTree{Int}(0)
        @test sum(ft0) == 0
    end
end
