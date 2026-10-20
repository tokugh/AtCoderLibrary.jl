using Test
using Random
using AtCoderLibrary

# ナイーブ実装(BigInt ベース)
math_naive_floor_sum(n, m, a, b) =
    sum((fld(big(a) * i + b, m) for i in 0:(n-1)); init = big(0))

function math_naive_crt(r, m)
    L = lcm(map(big, m)...)
    for x in 0:(L-1)
        all(mod(x, m[i]) == mod(r[i], m[i]) for i in eachindex(r)) &&
            return (Int64(x), Int64(L))
    end
    (Int64(0), Int64(0))
end

@testset "math" begin
    rng = MersenneTwister(20260711)

    @testset "pow_mod" begin
        @test pow_mod(0, 0, 1) == 0
        @test pow_mod(0, 0, 3) == 1
        @test pow_mod(2, 10, 1000) == 24
        @test pow_mod(-3, 3, 7) == mod((-3)^3, 7)
        for _ in 1:200
            x = rand(rng, -10^9:10^9)
            n = rand(rng, 0:10^9)
            m = rand(rng, 1:10^9)
            @test pow_mod(x, n, m) == powermod(mod(big(x), m), n, big(m))
        end
        @test_throws DomainError pow_mod(2, -1, 5)
        @test_throws DomainError pow_mod(2, 3, 0)
    end

    @testset "inv_mod" begin
        @test inv_mod(1, 1) == 0
        @test inv_mod(5, 1) == 0
        @test inv_mod(3, 7) == 5
        for _ in 1:200
            m = rand(rng, 1:10^9)
            x = rand(rng, -10^9:10^9)
            gcd(x, m) == 1 || continue
            y = inv_mod(x, m)
            @test 0 <= y < m
            @test m == 1 || mod(big(x) * y, m) == 1
        end
        @test_throws DomainError inv_mod(2, 4)
        @test_throws DomainError inv_mod(0, 3)
    end

    @testset "crt" begin
        @test crt(Int64[], Int64[]) == (0, 1)
        # 既知の例: x ≡ 2 (mod 3), x ≡ 3 (mod 5), x ≡ 2 (mod 7) → x ≡ 23 (mod 105)
        @test crt([2, 3, 2], [3, 5, 7]) == (23, 105)
        # 矛盾する例
        @test crt([0, 1], [2, 2]) == (0, 0)
        for _ in 1:300
            k = rand(rng, 1:4)
            m = [rand(rng, 1:12) for _ in 1:k]
            r = [rand(rng, -20:20) for _ in 1:k]
            got = crt(r, m)
            want = math_naive_crt(r, m)
            @test got == want
        end
        # 大きな法(互いに素)でも一致することの検証
        m1, m2 = 10^9 + 7, 998244353
        x = big(10)^17
        y, z = crt([mod(x, m1), mod(x, m2)], [m1, m2])
        @test z == Int64(m1) * m2
        @test mod(big(y), m1) == mod(x, m1) && mod(big(y), m2) == mod(x, m2)
    end

    @testset "floor_sum" begin
        @test floor_sum(0, 5, 3, 7) == 0
        # 小さい範囲の全数チェック
        for n in 0:8, m in 1:6, a in -6:6, b in -6:6
            @test floor_sum(n, m, a, b) == math_naive_floor_sum(n, m, a, b)
        end
        # ランダム(広い値域)
        for _ in 1:300
            n = rand(rng, 0:200)
            m = rand(rng, 1:10^9)
            a = rand(rng, -10^9:10^9)
            b = rand(rng, -10^9:10^9)
            @test floor_sum(n, m, a, b) == math_naive_floor_sum(n, m, a, b)
        end
        # 解析解との比較(n が大きいケース)
        n = 10^9
        @test floor_sum(n, 10^9, 0, 10^9 - 1) == 0
        @test floor_sum(n, 7, 0, 20) == n * fld(20, 7)
        @test floor_sum(n, 5, 5, 0) == n * (n - 1) ÷ 2
        @test_throws DomainError floor_sum(-1, 5, 1, 1)
        @test_throws DomainError floor_sum(5, 0, 1, 1)
    end
end
