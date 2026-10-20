# D の出力妥当性チェッカー(解が一意でないため出力一致ではなく整合性を検証する)
# 使い方: julia check_d.jl <input> <output> <expected_count>

function (@main)(ARGS)
    inp = readlines(ARGS[1])
    out = readlines(ARGS[2])
    expected = parse(Int, strip(read(ARGS[3], String)))

    n, m = parse.(Int, split(inp[1]))
    S = [collect(inp[1+i]) for i in 1:n]
    k = parse(Int, out[1])
    T = [collect(out[1+i]) for i in 1:n]

    @assert k == expected "タイル枚数 $k ≠ 期待値 $expected"
    tiles = 0
    for i in 1:n, j in 1:m
        s, t = S[i][j], T[i][j]
        if s == '#'
            @assert t == '#' "($i,$j): 障害物が書き換えられている"
        else
            @assert t in ('.', '>', '<', 'v', '^') "($i,$j): 不正な文字 $t"
        end
        if t == '>'
            @assert j < m && T[i][j+1] == '<' "($i,$j): > の右が < でない"
            tiles += 1
        elseif t == 'v'
            @assert i < n && T[i+1][j] == '^' "($i,$j): v の下が ^ でない"
            tiles += 1
        elseif t == '<'
            @assert j > 1 && T[i][j-1] == '>' "($i,$j): < の左が > でない"
        elseif t == '^'
            @assert i > 1 && T[i-1][j] == 'v' "($i,$j): ^ の上が v でない"
        end
    end
    @assert tiles == k "実際のタイル数 $tiles ≠ 申告値 $k"
    println("d: OK (tiles = $tiles)")
end
