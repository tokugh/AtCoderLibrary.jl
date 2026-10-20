using Test
using Random
using AtCoderLibrary

@testset "AtCoderLibrary" begin
    include("test_modint.jl")
    include("test_math.jl")
    include("test_dsu.jl")
    include("test_fenwicktree.jl")
    include("test_segtree.jl")
    include("test_lazysegtree.jl")
    include("test_string.jl")
    include("test_convolution.jl")
    include("test_scc.jl")
    include("test_twosat.jl")
    include("test_maxflow.jl")
    include("test_mincostflow.jl")
end
