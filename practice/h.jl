# H - Two SAT
# https://atcoder.jp/contests/practice2/tasks/practice2_h
using AtCoderLibrary
include(joinpath(@__DIR__, "..", "src", "TokenIO.jl"))

function (@main)(ARGS)
    input!()
    @input N::Int D::Int
    X = Vector{Int}(undef, N)
    Y = Vector{Int}(undef, N)
    for i in 1:N
        X[i] = nextI()
        Y[i] = nextI()
    end

    # x_i = true ⟺ 旗 i を X[i] に置く
    ts = TwoSAT(N)
    for i in 1:N, j in (i+1):N
        for (fi, ci) in ((true, X[i]), (false, Y[i]))
            for (fj, cj) in ((true, X[j]), (false, Y[j]))
                if abs(ci - cj) < D
                    # (x_i = fi) かつ (x_j = fj) は禁止
                    add_clause!(ts, i, !fi, j, !fj)
                end
            end
        end
    end

    if satisfiable!(ts)
        ans = answer(ts)
        println("Yes")
        for i in 1:N
            println(ans[i] ? X[i] : Y[i])
        end
    else
        println("No")
    end
end
