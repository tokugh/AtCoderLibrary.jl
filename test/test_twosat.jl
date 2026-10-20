using Test
using Random

# 総当たりで充足割り当てを探す (n ≤ 20 程度まで)
function twosat_test_brute(n, clauses)
    for mask in 0:(1 << n)-1
        assign = [((mask >> (i - 1)) & 1) == 1 for i in 1:n]
        if all((assign[i] == f) || (assign[j] == g) for (i, f, j, g) in clauses)
            return assign
        end
    end
    nothing
end

@testset "TwoSAT" begin
    @testset "固定ケース" begin
        # x1 ∧ ¬x1 は矛盾
        ts = TwoSAT(1)
        add_clause!(ts, 1, true, 1, true)
        add_clause!(ts, 1, false, 1, false)
        @test satisfiable!(ts) == false

        # x1 のみ
        ts = TwoSAT(1)
        add_clause!(ts, 1, true, 1, true)
        @test satisfiable!(ts)
        @test answer(ts) == [true]

        # 節なしは自明に充足可能
        @test satisfiable!(TwoSAT(0))
        @test satisfiable!(TwoSAT(3))

        # 範囲チェック
        ts = TwoSAT(2)
        @test_throws ArgumentError add_clause!(ts, 0, true, 1, true)
        @test_throws ArgumentError add_clause!(ts, 1, true, 3, true)
    end

    @testset "ランダム(総当たり突き合わせ)" begin
        rng = MersenneTwister(20260711)
        for _ in 1:500
            n = rand(rng, 1:8)
            m = rand(rng, 0:15)
            clauses = [
                (rand(rng, 1:n), rand(rng, Bool), rand(rng, 1:n), rand(rng, Bool))
                for _ in 1:m
            ]
            ts = TwoSAT(n)
            for (i, f, j, g) in clauses
                add_clause!(ts, i, f, j, g)
            end
            brute = twosat_test_brute(n, clauses)
            sat = satisfiable!(ts)
            @test sat == (brute !== nothing)
            if sat
                a = answer(ts)
                @test all((a[i] == f) || (a[j] == g) for (i, f, j, g) in clauses)
            end
        end
    end

    @testset "旗の配置 (Practice Contest H 相当)" begin
        # 旗 i は座標 xs[i] か ys[i] に置く。どの 2 本も距離 d 以上離す。
        # 変数 i が true ⟺ 旗 i を xs[i] に置く
        xs = [1, 2, 0, 3]
        ys = [4, 5, 6, 7]
        d = 2
        n = 4
        pos(i, b) = b ? xs[i] : ys[i]
        ts = TwoSAT(n)
        for i in 1:n, j in i+1:n, bi in (true, false), bj in (true, false)
            if abs(pos(i, bi) - pos(j, bj)) < d
                # 両立しない組: ¬(x_i = bi) ∨ ¬(x_j = bj)
                add_clause!(ts, i, !bi, j, !bj)
            end
        end
        @test satisfiable!(ts)
        a = answer(ts)
        chosen = [pos(i, a[i]) for i in 1:n]
        @test all(abs(chosen[i] - chosen[j]) >= d for i in 1:n for j in i+1:n)
    end
end
