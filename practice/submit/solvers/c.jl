# C - Floor Sum
# https://atcoder.jp/contests/practice2/tasks/practice2_c
function (@main)(ARGS)
    input!()
    t = nextI()
    for _ in 1:t
        n = nextI()
        m = nextI()
        a = nextI()
        b = nextI()
        println(floor_sum(n, m, a, b))   # 数式なので 0 起点のまま
    end
end
