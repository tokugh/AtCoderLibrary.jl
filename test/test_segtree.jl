using Test, Random
using AtCoderLibrary

# max モノイドのラッパー型イディオム(設計ノート §3)
struct SegMaxInt
    x::Int
end
Base.:*(a::SegMaxInt, b::SegMaxInt) = SegMaxInt(max(a.x, b.x))
Base.one(::Type{SegMaxInt}) = SegMaxInt(typemin(Int))

@testset "SegTree" begin
    seg_rng = MersenneTwister(20260711)

    @testset "文字列モノイド(非可換)" begin
        st = SegTree(["a", "b", "c", "d", "e"])
        @test prod(st, 2:4) == "bcd"
        @test prod(st, 3:2) == ""   # 空区間 = one(String)
        @test prod(st) == "abcde"
        st[3] = "X"
        @test prod(st, 1:5) == "abXde"
        @test st[3] == "X"
        @test length(st) == 5
    end

    @testset "ランダム: max ラッパー vs ナイーブ" begin
        for _ in 1:50
            n = rand(seg_rng, 1:30)
            a = rand(seg_rng, -100:100, n)
            st = SegTree([SegMaxInt(x) for x in a])
            for _ in 1:30
                if rand(seg_rng) < 0.3
                    i = rand(seg_rng, 1:n)
                    x = rand(seg_rng, -100:100)
                    a[i] = x
                    st[i] = SegMaxInt(x)
                end
                l = rand(seg_rng, 1:n)
                r = rand(seg_rng, 1:n)
                expected = l <= r ? maximum(a[l:r]) : typemin(Int)
                @test prod(st, l:r).x == expected
            end
        end
    end

    @testset "{S} 明示形: Union{Missing,Int} の min モノイド" begin
        # missing を単位元にすると typemax の番兵値が不要になる
        mop(a, b) = ismissing(a) ? b : ismissing(b) ? a : min(a, b)
        for _ in 1:30
            n = rand(seg_rng, 1:20)
            a = Vector{Union{Missing,Int}}(missing, n)
            for i in 1:n
                rand(seg_rng) < 0.5 && (a[i] = rand(seg_rng, -100:100))
            end
            st = SegTree{Union{Missing,Int}}(mop, missing, a)
            @test eltype(st) == Union{Missing,Int}
            for _ in 1:20
                if rand(seg_rng) < 0.3
                    i = rand(seg_rng, 1:n)
                    x = rand(seg_rng, Bool) ? missing : rand(seg_rng, -100:100)
                    st[i] = x
                    a[i] = x
                end
                l = rand(seg_rng, 1:n)
                r = rand(seg_rng, 1:n)
                vals = collect(skipmissing(a[max(l, 1):min(r, n)]))
                expected = (l > r || isempty(vals)) ? missing : minimum(vals)
                @test isequal(prod(st, l:r), expected)
            end
        end
        # n::Integer 版と、{S} 明示・無印(S = typeof(e))の等価性
        st0 = SegTree{Union{Missing,Int}}(mop, missing, 3)
        @test prod(st0) === missing
        st0[2] = 5
        @test prod(st0) == 5
        @test typeof(SegTree{Int}(max, 0, [1, 2])) == typeof(SegTree(max, 0, [1, 2]))
    end

    @testset "max_right / min_left vs ナイーブ" begin
        for _ in 1:30
            n = rand(seg_rng, 1:20)
            a = rand(seg_rng, 0:10, n)
            st = SegTree(+, 0, a)
            k = rand(seg_rng, 0:60)
            f = s -> s <= k
            for l in 1:(n+1)
                r = l - 1
                s = 0
                for j in l:n
                    s += a[j]
                    s <= k || break
                    r = j
                end
                @test max_right(st, l, f) == r
            end
            for r in 0:n
                l = r + 1
                s = 0
                for j in r:-1:1
                    s += a[j]
                    s <= k || break
                    l = j
                end
                @test min_left(st, r, f) == l
            end
        end
    end

    @testset "境界・エッジ" begin
        st0 = SegTree(String[])
        @test length(st0) == 0
        @test prod(st0) == ""
        @test max_right(st0, 1, s -> true) == 0
        @test min_left(st0, 0, s -> true) == 1

        st = SegTree(+, 0, [1, 2, 3])
        @test_throws BoundsError prod(st, 0:2)
        @test_throws BoundsError prod(st, 1:4)
        @test_throws BoundsError st[4]
        @test_throws AssertionError max_right(st, 1, s -> s > 0)  # f(e) == false
        # 全域 true / 空のみ true
        @test max_right(st, 1, s -> true) == 3
        @test max_right(st, 1, s -> s <= 0) == 0    # l - 1
        @test min_left(st, 3, s -> true) == 1
        @test min_left(st, 3, s -> s <= 0) == 4     # r + 1
        # do 記法
        res = max_right(st, 1) do s
            s <= 3
        end
        @test res == 2
    end
end
