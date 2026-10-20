# D - Maxflow(1×2 タイルの最大充填 = 二部マッチング)
# https://atcoder.jp/contests/practice2/tasks/practice2_d
using AtCoderLibrary
include(joinpath(@__DIR__, "..", "src", "TokenIO.jl"))

function (@main)(ARGS)
    input!()
    @input n::Int m::Int
    S = [collect(nextS()) for _ in 1:n]
    cid(i, j) = (i - 1) * m + j
    s = n * m + 1
    t = n * m + 2
    g = MFGraph{Int}(n * m + 2)
    for i in 1:n, j in 1:m
        S[i][j] == '.' || continue
        if iseven(i + j)   # 二部グラフの片側(市松の色)
            add_edge!(g, s, cid(i, j), 1)
            for (di, dj) in ((0, 1), (0, -1), (1, 0), (-1, 0))
                ni, nj = i + di, j + dj
                (1 <= ni <= n && 1 <= nj <= m && S[ni][nj] == '.') || continue
                add_edge!(g, cid(i, j), cid(ni, nj), 1)
            end
        else
            add_edge!(g, cid(i, j), t, 1)
        end
    end
    f = flow!(g, s, t)
    println(f)
    for e in edges(g)
        (e.from != s && e.to != t && e.flow == 1) || continue
        i1, j1 = divrem(e.from - 1, m) .+ 1
        i2, j2 = divrem(e.to - 1, m) .+ 1
        if i1 == i2
            S[i1][min(j1, j2)] = '>'
            S[i1][max(j1, j2)] = '<'
        else
            S[min(i1, i2)][j1] = 'v'
            S[max(i1, i2)][j1] = '^'
        end
    end
    for i in 1:n
        join(stdout, S[i])
        println()
    end
end
