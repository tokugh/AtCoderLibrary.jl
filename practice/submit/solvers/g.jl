# G - SCC
# https://atcoder.jp/contests/practice2/tasks/practice2_g
function (@main)(ARGS)
    input!()
    N = nextI(); M = nextI()
    g = SCCGraph(N)
    for _ in 1:M
        a = nextI()
        b = nextI()
        add_edge!(g, a + 1, b + 1)   # 入力は 0-indexed
    end
    comps = scc(g)
    println(length(comps))
    for c in comps
        print(length(c))
        for v in c
            print(' ', v - 1)   # 出力は 0-indexed
        end
        println()
    end
end
