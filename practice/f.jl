# F - Convolution
# https://atcoder.jp/contests/practice2/tasks/practice2_f
using AtCoderLibrary
include(joinpath(@__DIR__, "..", "src", "TokenIO.jl"))

function (@main)(ARGS)
    input!()
    @input N::Int M::Int a::[Int, N] b::[Int, M]
    c = convolution(998244353, a, b)
    join(stdout, c, ' ')
    println()
end
