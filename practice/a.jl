# A - Disjoint Set Union
# https://atcoder.jp/contests/practice2/tasks/practice2_a
using AtCoderLibrary
include(joinpath(@__DIR__, "..", "src", "TokenIO.jl"))

function (@main)(ARGS)
    input!()
    @input n::Int q::Int
    d = DSU(n)
    for _ in 1:q
        t = nextI()
        u = nextI() + 1   # 0-indexed 入力 → 1-indexed API
        v = nextI() + 1
        if t == 0
            merge!(d, u, v)
        else
            println(same(d, u, v) ? 1 : 0)
        end
    end
end
