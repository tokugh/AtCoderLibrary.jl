# C++ 版 ACL との突き合わせ用ランダム入力生成器(決定的シード)
using Random

const rng = MersenneTwister(20260711)
const dir = joinpath(@__DIR__, "tmp")
mkpath(dir)

# ---- fenwick: n q / "0 p x"(add)| "1 l r"(sum, 半開) ----
open(joinpath(dir, "fenwick.in"), "w") do io
    T = 100
    println(io, T)
    for _ in 1:T
        n = rand(rng, 0:20) == 0 ? 0 : rand(rng, 1:200)
        q = n == 0 ? 0 : rand(rng, 1:200)
        println(io, n, " ", q)
        for _ in 1:q
            if rand(rng) < 0.5
                println(io, "0 ", rand(rng, 0:n-1), " ", rand(rng, -1000:1000))
            else
                l = rand(rng, 0:n)
                r = rand(rng, l:n)
                println(io, "1 ", l, " ", r)
            end
        end
    end
end

# ---- segtree: mono n q / 0 p x | 1 l r | 2 | 3 l k | 4 r k ----
open(joinpath(dir, "segtree.in"), "w") do io
    T = 100
    println(io, T)
    for t in 1:T
        mono = t <= 50 ? 0 : 1   # 0: max(値 0..1e9, e=0), 1: 和(値 0..1000)
        n = rand(rng, 1:200)
        q = rand(rng, 1:200)
        println(io, mono, " ", n, " ", q)
        for _ in 1:q
            c = rand(rng, 0:4)
            if c == 0
                x = mono == 0 ? rand(rng, 0:10^9) : rand(rng, 0:1000)
                println(io, "0 ", rand(rng, 0:n-1), " ", x)
            elseif c == 1
                l = rand(rng, 0:n)
                r = rand(rng, l:n)
                println(io, "1 ", l, " ", r)
            elseif c == 2
                println(io, "2")
            elseif c == 3
                k = mono == 0 ? rand(rng, 1:10^9+1) : rand(rng, 1:200_001)
                println(io, "3 ", rand(rng, 0:n), " ", k)
            else
                k = mono == 0 ? rand(rng, 1:10^9+1) : rand(rng, 1:200_001)
                println(io, "4 ", rand(rng, 0:n), " ", k)
            end
        end
    end
end

# ---- lazyseg: n q / 0 l r b c | 1 l r | 2 p x | 3 p | 4 l k ----
const MOD = 998244353
open(joinpath(dir, "lazyseg.in"), "w") do io
    T = 60
    println(io, T)
    for _ in 1:T
        n = rand(rng, 1:150)
        q = rand(rng, 1:150)
        println(io, n, " ", q)
        for _ in 1:q
            c = rand(rng, 0:4)
            if c == 0
                l = rand(rng, 0:n)
                r = rand(rng, l:n)
                println(io, "0 ", l, " ", r, " ", rand(rng, 0:MOD-1), " ", rand(rng, 0:MOD-1))
            elseif c == 1
                l = rand(rng, 0:n)
                r = rand(rng, l:n)
                println(io, "1 ", l, " ", r)
            elseif c == 2
                println(io, "2 ", rand(rng, 0:n-1), " ", rand(rng, 0:MOD-1))
            elseif c == 3
                println(io, "3 ", rand(rng, 0:n-1))
            else
                println(io, "4 ", rand(rng, 0:n), " ", rand(rng, 1:MOD))
            end
        end
    end
end

# ---- conv: mode n m / a / b(mode 0: mod 998244353, 1: ll)----
open(joinpath(dir, "conv.in"), "w") do io
    T = 60
    println(io, T)
    for t in 1:T
        mode = t <= 30 ? 0 : 1
        n = rand(rng, 0:15) == 0 ? 0 : rand(rng, 1:250)
        m = rand(rng, 0:15) == 0 ? 0 : rand(rng, 1:250)
        println(io, mode, " ", n, " ", m)
        hi = mode == 0 ? (0:MOD-1) : (-10^8:10^8)
        println(io, join(rand(rng, hi, n), ' '))
        println(io, join(rand(rng, hi, m), ' '))
    end
end

# ---- math: 0 n m a b(floor_sum)| 1 k / r... / m...(crt) ----
open(joinpath(dir, "math.in"), "w") do io
    T = 400
    println(io, T)
    for t in 1:T
        if t <= 200
            n = rand(rng, Bool) ? rand(rng, 0:20) : rand(rng, 0:10^9)
            m = rand(rng, Bool) ? rand(rng, 1:20) : rand(rng, 1:10^9)
            a = rand(rng, -10^9:10^9)
            b = rand(rng, -10^9:10^9)
            println(io, "0 ", n, " ", m, " ", a, " ", b)
        else
            k = rand(rng, 0:5)
            r = [rand(rng, -100:100) for _ in 1:k]
            m = [rand(rng, 1:30) for _ in 1:k]
            println(io, "1 ", k)
            println(io, join(r, ' '))
            println(io, join(m, ' '))
        end
    end
end

# ---- string: 0 s | 1 n v...(n ≥ 1)----
open(joinpath(dir, "string.in"), "w") do io
    T = 120
    println(io, T)
    for t in 1:T
        if t <= 60
            σ = rand(rng, 1:26)
            len = rand(rng, 1:200)
            s = String(rand(rng, 'a':('a'+σ-1), len))
            println(io, "0 ", s)
        else
            n = rand(rng, 1:200)
            v = rand(rng, Bool) ? rand(rng, 0:5, n) : rand(rng, -10^9:10^9, n)
            println(io, "1 ", n)
            println(io, join(v, ' '))
        end
    end
end

# ---- scc: n m / u v ----
open(joinpath(dir, "scc.in"), "w") do io
    T = 100
    println(io, T)
    for _ in 1:T
        n = rand(rng, 1:50)
        m = rand(rng, 0:100)
        println(io, n, " ", m)
        for _ in 1:m
            println(io, rand(rng, 0:n-1), " ", rand(rng, 0:n-1))
        end
    end
end

# ---- maxflow: n m / u v cap(s=0, t=n-1, 自己ループ可)----
open(joinpath(dir, "maxflow.in"), "w") do io
    T = 100
    println(io, T)
    for _ in 1:T
        n = rand(rng, 2:30)
        m = rand(rng, 0:100)
        println(io, n, " ", m)
        for _ in 1:m
            println(io, rand(rng, 0:n-1), " ", rand(rng, 0:n-1), " ", rand(rng, 0:100))
        end
    end
end

# ---- mincostflow: n m / u v cap cost(u ≠ v)----
open(joinpath(dir, "mincostflow.in"), "w") do io
    T = 80
    println(io, T)
    for _ in 1:T
        n = rand(rng, 2:20)
        m = rand(rng, 0:60)
        println(io, n, " ", m)
        for _ in 1:m
            u = rand(rng, 0:n-1)
            v = rand(rng, 0:n-2)
            v >= u && (v += 1)
            println(io, u, " ", v, " ", rand(rng, 0:30), " ", rand(rng, 0:30))
        end
    end
end

# ---- dsu: n q / 0 u v(merge)| 1 u v(same)| 2 u(size)----
open(joinpath(dir, "dsu.in"), "w") do io
    T = 100
    println(io, T)
    for _ in 1:T
        n = rand(rng, 1:100)
        q = rand(rng, 1:200)
        println(io, n, " ", q)
        for _ in 1:q
            c = rand(rng, 0:2)
            if c == 2
                println(io, "2 ", rand(rng, 0:n-1))
            else
                println(io, c, " ", rand(rng, 0:n-1), " ", rand(rng, 0:n-1))
            end
        end
    end
end

println("generated inputs in ", dir)
