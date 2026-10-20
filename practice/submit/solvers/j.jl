# J - Segment Tree
# max モノイドの SegTree。Type 3 は境界探索:
# 「x_j ≥ v となる最小の j」 = max_right(st, x, s -> s < v) + 1
# (max_right は f(prod(l:r)) が true な最大の r を返す true 側ラベル規約。
#  全域 true なら n が返り、+1 で N+1 になり問題の要求と一致する)
function (@main)(ARGS)
    input!()
    N = nextI(); Q = nextI()
    A = [nextI() for _ in 1:N]
    st = SegTree(max, typemin(Int), A)
    for _ in 1:Q
        t = nextI()
        if t == 1
            x = nextI()
            v = nextI()
            st[x] = v
        elseif t == 2
            l = nextI()
            r = nextI()
            println(prod(st, l:r))
        else
            x = nextI()
            v = nextI()
            println(max_right(st, x, s -> s < v) + 1)
        end
    end
end
