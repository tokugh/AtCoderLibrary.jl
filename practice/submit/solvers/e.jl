# E - MinCostFlow
# https://atcoder.jp/contests/practice2/tasks/practice2_e
function (@main)(ARGS)
    input!()
    N = nextI(); K = nextI()
    A = Matrix{Int}(undef, N, N)
    for i in 1:N, j in 1:N
        A[i, j] = nextI()
    end

    BIG = 10^9
    # 頂点: 1 = s, 2 = t, 2+i = 行 i, 2+N+j = 列 j
    s, t = 1, 2
    g = MCFGraph{Int,Int}(2 + 2N)
    add_edge!(g, s, t, N * K, BIG)          # 使わない流量の逃げ道
    for i in 1:N
        add_edge!(g, s, 2 + i, K, 0)
    end
    for j in 1:N
        add_edge!(g, 2 + N + j, t, K, 0)
    end
    eid = Matrix{Int}(undef, N, N)
    for i in 1:N, j in 1:N
        eid[i, j] = add_edge!(g, 2 + i, 2 + N + j, 1, BIG - A[i, j])
    end

    _, cost = flow!(g, s, t, N * K)
    println(N * K * BIG - cost)
    for i in 1:N
        for j in 1:N
            print(get_edge(g, eid[i, j]).flow == 1 ? 'X' : '.')
        end
        println()
    end
end
