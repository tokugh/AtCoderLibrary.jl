using Test, Random
using AtCoderLibrary

# 区間加算・区間和:S = (和, 長さ), F = Int
lst_op(a, b) = (a[1] + b[1], a[2] + b[2])
lst_mapping(f, x) = (x[1] + f * x[2], x[2])

@testset "LazySegTree" begin
    lst_rng = MersenneTwister(20260713)

    @testset "区間加算・区間和 vs ナイーブ" begin
        for _ in 1:30
            n = rand(lst_rng, 1:25)
            a = rand(lst_rng, -50:50, n)
            st = LazySegTree(lst_op, (0, 0), lst_mapping, +, 0, [(x, 1) for x in a])
            for _ in 1:50
                c = rand(lst_rng, 1:4)
                l = rand(lst_rng, 1:n)
                r = rand(lst_rng, 1:n)
                if c == 1
                    f = rand(lst_rng, -20:20)
                    apply!(st, l:r, f)
                    l <= r && (a[l:r] .+= f)
                elseif c == 2
                    i = rand(lst_rng, 1:n)
                    x = rand(lst_rng, -50:50)
                    st[i] = (x, 1)
                    a[i] = x
                elseif c == 3
                    i = rand(lst_rng, 1:n)
                    @test st[i] == (a[i], 1)
                else
                    expected = l <= r ? sum(a[l:r]) : 0
                    @test prod(st, l:r)[1] == expected
                end
            end
            @test prod(st)[1] == sum(a)
        end
    end

    @testset "区間 affine・区間和 (ModInt)" begin
        M = ModInt998244353
        # S = (和, 長さ), F = (b, c) : x ↦ b*x + c
        aff_op(x, y) = (x[1] + y[1], x[2] + y[2])
        aff_map(f, x) = (f[1] * x[1] + f[2] * x[2], x[2])
        aff_comp(f, g) = (f[1] * g[1], f[1] * g[2] + f[2])
        for _ in 1:20
            n = rand(lst_rng, 1:20)
            a = [M(rand(lst_rng, 0:100)) for _ in 1:n]
            st = LazySegTree(aff_op, (zero(M), zero(M)), aff_map, aff_comp,
                             (one(M), zero(M)), [(x, one(M)) for x in a])
            for _ in 1:40
                l = rand(lst_rng, 1:n)
                r = rand(lst_rng, 1:n)
                if rand(lst_rng) < 0.5
                    b = M(rand(lst_rng, 0:100))
                    c = M(rand(lst_rng, 0:100))
                    apply!(st, l:r, (b, c))
                    l <= r && (a[l:r] .= b .* a[l:r] .+ c)
                else
                    expected = l <= r ? sum(a[l:r]; init=zero(M)) : zero(M)
                    @test prod(st, l:r)[1] == expected
                end
            end
        end
    end

    @testset "max_right / min_left vs ナイーブ" begin
        for _ in 1:20
            n = rand(lst_rng, 1:15)
            a = rand(lst_rng, 0:10, n)
            st = LazySegTree(lst_op, (0, 0), lst_mapping, +, 0, [(x, 1) for x in a])
            k = rand(lst_rng, 0:40)
            f = s -> s[1] <= k
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

    @testset "一点 apply!・エッジ" begin
        st = LazySegTree(lst_op, (0, 0), lst_mapping, +, 0, [(x, 1) for x in [1, 2, 3]])
        apply!(st, 2, 10)
        @test st[2] == (12, 1)
        @test prod(st, 1:3)[1] == 16
        apply!(st, 2:1, 100)   # 空区間:何もしない
        @test prod(st)[1] == 16
        @test_throws BoundsError apply!(st, 0:2, 1)
        @test_throws BoundsError st[4]

        st0 = LazySegTree(lst_op, (0, 0), lst_mapping, +, 0, Tuple{Int,Int}[])
        @test length(st0) == 0
        @test prod(st0) == (0, 0)
        @test max_right(st0, 1, s -> true) == 0
    end
end
