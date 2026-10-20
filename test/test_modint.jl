using Test
using Random
using AtCoderLibrary

@testset "modint" begin
    @testset "基本演算" begin
        a = ModInt{7}(3); b = ModInt{7}(5)
        @test val(a + b) == 1
        @test val(a - b) == 5
        @test val(a * b) == 1
        @test a / b == a * inv(b)
        @test val(-a) == 4
        @test val(-ModInt{7}(0)) == 0
        @test ModInt{7}(-1) == ModInt{7}(6)
        @test val(ModInt{7}(21)) == 0
    end

    @testset "整数との昇格" begin
        a = ModInt{7}(3)
        @test a + 1 == ModInt{7}(4)
        @test 1 + a == ModInt{7}(4)
        @test a - 5 == ModInt{7}(5)
        @test 2a == ModInt{7}(6)
        @test a / 5 == a * inv(ModInt{7}(5))
        @test ModInt{7}(3) == 3  # 昇格して比較
        v = ModInt{7}[1, 2]     # convert 経由の代入
        v[1] = 10
        @test val(v[1]) == 3
    end

    @testset "べき乗・逆元" begin
        @test val(ModInt998244353(10)^18) == powermod(10, 18, 998244353)
        @test val(ModInt{7}(3)^0) == 1
        @test val(ModInt{7}(0)^0) == 1
        @test ModInt{7}(3)^-1 == inv(ModInt{7}(3))
        @test ModInt{7}(3)^-2 == inv(ModInt{7}(3))^2
        for x in 1:6
            @test val(inv(ModInt{7}(x)) * x) == 1
        end
        # 互いに素でない場合は DomainError(invmod 準拠)
        @test_throws DomainError inv(ModInt{4}(2))
        # 非素数の法でも互いに素なら逆元あり
        @test val(inv(ModInt{10}(3)) * 3) == 1
    end

    @testset "zero / one / 集約" begin
        @test val(zero(ModInt998244353)) == 0
        @test val(one(ModInt998244353)) == 1
        @test iszero(zero(ModInt{7}))
        @test isone(one(ModInt{7}))
        @test sum(ModInt{7}.(1:6)) == ModInt{7}(21)
        @test prod(ModInt{7}.(1:6)) == ModInt{7}(720)
    end

    @testset "mod 1(すべて 0)" begin
        @test val(ModInt{1}(3)) == 0
        @test val(one(ModInt{1})) == 0
        @test isone(one(ModInt{1}))
        @test iszero(zero(ModInt{1}))
        @test val(ModInt{1}(0) + ModInt{1}(5)) == 0
        @test val(ModInt{1}(2) * ModInt{1}(3)) == 0
    end

    @testset "ランダム演算(BigInt 突き合わせ)" begin
        rng = MersenneTwister(20260711)
        for M in (998244353, 1000000007, 7, 2, 1 << 30, (1 << 31) - 1)
            for _ in 1:200
                x = rand(rng, -10^18:10^18)
                y = rand(rng, -10^18:10^18)
                a, b = ModInt{M}(x), ModInt{M}(y)
                @test val(a + b) == mod(big(x) + big(y), M)
                @test val(a - b) == mod(big(x) - big(y), M)
                @test val(a * b) == mod(big(x) * big(y), M)
                @test val(-a) == mod(-big(x), M)
                e = rand(rng, 0:40)
                @test val(a^e) == mod(big(x)^e, M)
            end
        end
    end
end
