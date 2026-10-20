using Test
using Random
using AtCoderLibrary

# ---- ナイーブ実装(検証用)----

function str_lex_less(a, b)
    na, nb = length(a), length(b)
    i = 1
    while i <= na && i <= nb
        a[i] != b[i] && return a[i] < b[i]
        i += 1
    end
    return na < nb
end

str_sa_naive(v::AbstractVector) =
    sort(collect(1:length(v)), lt = (l, r) -> str_lex_less(v[l:end], v[r:end]))
str_sa_naive(s::AbstractString) = str_sa_naive(collect(codeunits(s)))

function str_common_prefix(a, b)
    k = 0
    while k < length(a) && k < length(b) && a[k+1] == b[k+1]
        k += 1
    end
    return k
end

str_lcp_naive(v::AbstractVector, sa) =
    [str_common_prefix(v[sa[i]:end], v[sa[i+1]:end]) for i in 1:length(v)-1]
str_lcp_naive(s::AbstractString, sa) = str_lcp_naive(collect(codeunits(s)), sa)

str_z_naive(v::AbstractVector) = [str_common_prefix(v, v[i:end]) for i in 1:length(v)]
str_z_naive(s::AbstractString) = str_z_naive(collect(codeunits(s)))

str_rand_string(rng, n, σ) = String(rand(rng, ('a':'z')[1:σ], n))

@testset "string" begin
    rng = MersenneTwister(0x5757)

    @testset "suffix_array 固定ケース" begin
        @test suffix_array("") == Int[]
        @test suffix_array("a") == [1]
        @test suffix_array("ab") == [1, 2]
        @test suffix_array("ba") == [2, 1]
        @test suffix_array("aaaa") == [4, 3, 2, 1]
        for s in ("abracadabra", "mississippi", "abcbcba", "aabaaaab",
                  "missississippi", repeat("ab", 40), repeat("a", 100))
            @test suffix_array(s) == str_sa_naive(s)
        end
    end

    @testset "suffix_array ランダム(文字列)" begin
        # 長さ 1..60 でナイーブ・倍加・SA-IS の全分岐を跨ぐ
        for n in vcat(1:60, [100, 200, 400, 1000]), σ in (1, 2, 3, 26)
            s = str_rand_string(rng, n, σ)
            @test suffix_array(s) == str_sa_naive(s)
        end
    end

    @testset "suffix_array (v, upper) 版" begin
        for n in vcat(1:40, [100, 300]), upper in (0, 1, 2, 10)
            v = rand(rng, 0:upper, n)
            @test suffix_array(v, upper) == str_sa_naive(v)
        end
        @test_throws ArgumentError suffix_array([0, 3, 1], 2)
        @test_throws ArgumentError suffix_array([-1, 0], 5)
        @test_throws ArgumentError suffix_array([0, 1], -1)
    end

    @testset "suffix_array 汎用ベクタ版(座標圧縮)" begin
        for n in vcat(1:40, [100, 300])
            v = rand(rng, [-10^9, -5, 0, 3, 10^9], n)
            @test suffix_array(v) == str_sa_naive(v)
        end
        # Char ベクタも順序付きなら通る
        v = collect("cabbage")
        @test suffix_array(v) == str_sa_naive(v)
        @test suffix_array(Int[]) == Int[]
    end

    @testset "suffix_array 3 メソッドの一致" begin
        for n in (10, 50, 200)
            s = str_rand_string(rng, n, 3)
            b = collect(codeunits(s))
            sa = suffix_array(s)
            @test suffix_array(Int.(b), 255) == sa
            @test suffix_array(b) == sa
        end
    end

    @testset "lcp_array" begin
        for s in ("aab", "abracadabra", "mississippi", repeat("ab", 30))
            sa = suffix_array(s)
            @test lcp_array(s, sa) == str_lcp_naive(s, sa)
        end
        for n in vcat(1:30, [100, 500]), σ in (1, 2, 26)
            s = str_rand_string(rng, n, σ)
            sa = suffix_array(s)
            @test lcp_array(s, sa) == str_lcp_naive(s, sa)
        end
        # ベクタ入力
        v = rand(rng, 0:2, 200)
        sa = suffix_array(v, 2)
        @test lcp_array(v, sa) == str_lcp_naive(v, sa)
        @test lcp_array("a", [1]) == Int[]
        @test_throws ArgumentError lcp_array("", Int[])
    end

    @testset "z_algorithm" begin
        @test z_algorithm("") == Int[]
        @test z_algorithm("a") == [1]
        @test z_algorithm("ababab") == [6, 0, 4, 0, 2, 0]
        @test z_algorithm("aaaa") == [4, 3, 2, 1]
        @test z_algorithm("abracadabra") == str_z_naive("abracadabra")
        for n in vcat(1:50, [200, 1000]), σ in (1, 2, 3)
            s = str_rand_string(rng, n, σ)
            @test z_algorithm(s) == str_z_naive(s)
        end
        v = rand(rng, 0:1, 300)
        @test z_algorithm(v) == str_z_naive(v)
    end
end
