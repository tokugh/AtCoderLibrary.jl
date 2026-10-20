# F - Convolution
# https://atcoder.jp/contests/practice2/tasks/practice2_f
function (@main)(ARGS)
    input!()
    N = nextI(); M = nextI()
    a = [nextI() for _ in 1:N]
    b = [nextI() for _ in 1:M]
    c = convolution(998244353, a, b)
    join(stdout, c, ' ')
    println()
end
