using Test
using Random
using AtCoderLibrary

# ナイーブ参照実装(BigInt、mod あり)
function conv_ref_mod(a::AbstractVector{<:Integer}, b::AbstractVector{<:Integer}, M::Integer)
    n, m = length(a), length(b)
    (n == 0 || m == 0) && return Int64[]
    c = zeros(BigInt, n + m - 1)
    for i in 1:n, j in 1:m
        c[i + j - 1] += big(a[i]) * big(b[j])
    end
    Int64[mod(x, M) for x in c]
end

# ナイーブ参照実装(BigInt、正確な値)
function conv_ref_exact(a::AbstractVector{<:Integer}, b::AbstractVector{<:Integer})
    n, m = length(a), length(b)
    (n == 0 || m == 0) && return BigInt[]
    c = zeros(BigInt, n + m - 1)
    for i in 1:n, j in 1:m
        c[i + j - 1] += big(a[i]) * big(b[j])
    end
    c
end

@testset "convolution" begin
    Mint = ModInt998244353

    @testset "空・長さ 1" begin
        @test convolution(Mint[], Mint[]) == Mint[]
        @test convolution(Mint[], Mint.([1, 2])) == Mint[]
        @test convolution(Mint.([1, 2]), Mint[]) == Mint[]
        @test convolution(Mint.([5]), Mint.([7])) == Mint.([35])
        @test convolution(998244353, Int64[], Int64[1]) == Int64[]
        @test convolution(998244353, [3], [4]) == Int64[12]
        @test convolution_ll(Int64[], Int64[1]) == Int64[]
        @test convolution_ll([3], [-4]) == Int64[-12]
    end

    @testset "ランダム mod 998244353(ナイーブ突き合わせ)" begin
        rng = MersenneTwister(1)
        for _ in 1:30
            n = rand(rng, 1:300)
            m = rand(rng, 1:300)
            a = rand(rng, 0:998244352, n)
            b = rand(rng, 0:998244352, m)
            expect = conv_ref_mod(a, b, 998244353)
            @test convolution(998244353, a, b) == expect
            @test val.(convolution(Mint.(a), Mint.(b))) == expect
        end
    end

    @testset "ナイーブ/FFT 境界(サイズ 60 前後)" begin
        rng = MersenneTwister(2)
        for n in (59, 60, 61, 62), m in (60, 61, 100)
            a = rand(rng, 0:998244352, n)
            b = rand(rng, 0:998244352, m)
            @test convolution(998244353, a, b) == conv_ref_mod(a, b, 998244353)
        end
    end

    @testset "負数を含む入力の mod 畳み込み" begin
        rng = MersenneTwister(4)
        a = rand(rng, -10^9:10^9, 80)
        b = rand(rng, -10^9:10^9, 80)
        @test convolution(998244353, a, b) == conv_ref_mod(a, b, 998244353)
    end

    @testset "NTT-unfriendly な法" begin
        rng = MersenneTwister(5)
        # 短い入力はナイーブに落ちるので任意の法で動く
        a = rand(rng, 0:10^9 + 6, 30)
        b = rand(rng, 0:10^9 + 6, 40)
        @test convolution(1000000007, a, b) == conv_ref_mod(a, b, 1000000007)
        # 1000000007 - 1 は 2 で 1 回しか割れないため、長い入力は ArgumentError
        a61 = rand(rng, 0:10^9, 61)
        b61 = rand(rng, 0:10^9, 61)
        @test_throws ArgumentError convolution(1000000007, a61, b61)
    end

    @testset "convolution_ll(BigInt 突き合わせ)" begin
        rng = MersenneTwister(3)
        for _ in 1:15
            n = rand(rng, 1:150)
            m = rand(rng, 1:150)
            a = rand(rng, -10^8:10^8, n)
            b = rand(rng, -10^8:10^8, m)
            @test big.(convolution_ll(a, b)) == conv_ref_exact(a, b)
        end
        # FFT 経路(両方 > 60)を明示的に踏む
        a = rand(rng, -10^8:10^8, 100)
        b = rand(rng, -10^8:10^8, 100)
        @test big.(convolution_ll(a, b)) == conv_ref_exact(a, b)
    end

    @testset "convolution_ll の極値付近" begin
        # |結果| < 2^63 ぎりぎりの値
        @test convolution_ll([4 * 10^9], [2 * 10^9]) == [8 * 10^18]
        @test convolution_ll([-4 * 10^9], [2 * 10^9]) == [-8 * 10^18]
        @test convolution_ll([3 * 10^9, -3 * 10^9], [10^9, 10^9]) ==
              [3 * 10^18, 0, -3 * 10^18]
    end
end
