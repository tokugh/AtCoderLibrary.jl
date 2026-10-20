# I - Number of Substrings
# 相異なる部分文字列の個数 = n(n+1)/2 - Σ lcp
using AtCoderLibrary
include(joinpath(@__DIR__, "..", "src", "TokenIO.jl"))

function (@main)(ARGS)
    input!()
    s = nextS()
    n = ncodeunits(s)
    sa = suffix_array(s)
    lcp = lcp_array(s, sa)
    println(n * (n + 1) ÷ 2 - sum(lcp; init=0))
end
