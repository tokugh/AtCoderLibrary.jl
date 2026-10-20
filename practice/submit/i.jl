# ==== 入力(TokenIO ワンライナー版)====
const _IN = Ref(""); const _POS = Ref(1)
input!() = (_IN[] = read(stdin, String); _POS[] = 1; nothing)
@inline function nextI(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; neg = false; @inbounds if p <= n && codeunit(s, p) == 0x2d; neg = true; p += 1; end; x = 0; @inbounds while p <= n; c = codeunit(s, p); (0x30 <= c <= 0x39) || break; x = 10x + Int(c - 0x30); p += 1; end; _POS[] = p; return neg ? -x : x; end
@inline function nextS(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; p > n && return SubString(s, 1, 0); q = p; @inbounds while q <= n && codeunit(s, q) > 0x20; q += 1; end; _POS[] = q; return SubString(s, p, thisind(s, q - 1)); end
nextF() = parse(Float64, nextS())
function nextC(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; p > n && return '\0'; c = s[p]; _POS[] = nextind(s, p); return c; end

# I - Number of Substrings
# 相異なる部分文字列の個数 = n(n+1)/2 - Σ lcp
function (@main)(ARGS)
    input!()
    s = nextS()
    n = ncodeunits(s)
    sa = suffix_array(s)
    lcp = lcp_array(s, sa)
    println(n * (n + 1) ÷ 2 - sum(lcp; init=0))
end

# ==== ライブラリ: string.jl ====
# string.jl — suffix_array / lcp_array / z_algorithm
#
# C++ 版 ACL (atcoder/string.hpp) の移植。内部の SA-IS は位置・文字値とも
# 1-indexed(文字値は 1..σ)で自然に書き直している。

# ナイーブな接尾辞配列(n < 10 用)。s は値 1..σ の Int 列、返り値は 1-indexed 開始位置
function _sa_naive(s::Vector{Int})
    n = length(s)
    sa = collect(1:n)
    sort!(sa, lt = (l, r) -> begin
        l == r && return false
        while l <= n && r <= n
            s[l] != s[r] && return s[l] < s[r]
            l += 1
            r += 1
        end
        l == n + 1  # 左側が先に尽きた(= 他方の真の接頭辞)なら小さい
    end)
    return sa
end

# 倍加法 O(n log^2 n)(n < 40 用)
function _sa_doubling(s::Vector{Int})
    n = length(s)
    sa = collect(1:n)
    rnk = copy(s)
    tmp = zeros(Int, n)
    k = 1
    while k < n
        # rnk・k はループ末尾で再束縛されるため、クロージャに直接捕捉させると
        # ボックス化されて比較のたびに動的ディスパッチが起きる。let で束縛を固定する
        cmp = let rnk = rnk, k = k
            (x, y) -> begin
                rnk[x] != rnk[y] && return rnk[x] < rnk[y]
                rx = x + k <= n ? rnk[x+k] : -1
                ry = y + k <= n ? rnk[y+k] : -1
                return rx < ry
            end
        end
        sort!(sa, lt = cmp)
        tmp[sa[1]] = 0
        for i in 2:n
            tmp[sa[i]] = tmp[sa[i-1]] + (cmp(sa[i-1], sa[i]) ? 1 : 0)
        end
        rnk, tmp = tmp, rnk
        k *= 2
    end
    return sa
end

# SA-IS 本体 O(n)。s の値は 1..σ、返り値は 1-indexed 開始位置の列
#
# 参考: G. Nong, S. Zhang, and W. H. Chan,
# Two Efficient Algorithms for Linear Time Suffix Array Construction
function _sa_is(s::Vector{Int}, σ::Int)
    n = length(s)
    n == 0 && return Int[]
    n == 1 && return [1]
    n == 2 && return s[1] < s[2] ? [1, 2] : [2, 1]
    n < 10 && return _sa_naive(s)
    n < 40 && return _sa_doubling(s)

    sa = zeros(Int, n)          # 0 = 未配置
    ls = falses(n)              # true = S 型、false = L 型(末尾は L 型扱い)
    for i in (n-1):-1:1
        ls[i] = s[i] == s[i+1] ? ls[i+1] : s[i] < s[i+1]
    end
    # プレフィックス和の後、sum_l[c] / sum_s[c] は文字 c の L 領域 / S 領域の
    # 直前の位置(配置済みカウンタ)になる。書き込みは +1 した位置に行う
    sum_l = zeros(Int, σ + 1)
    sum_s = zeros(Int, σ + 1)
    for i in 1:n
        if !ls[i]
            sum_s[s[i]] += 1        # この時点では L 型の個数
        else
            sum_l[s[i]+1] += 1      # この時点では S 型の個数
        end
    end
    for c in 1:σ
        sum_s[c] += sum_l[c]
        c < σ && (sum_l[c+1] += sum_s[c])
    end

    buf = zeros(Int, σ + 1)
    # LMS 位置の列を受け取り、誘導ソートで sa を埋める
    induce! = lms_positions -> begin
        fill!(sa, 0)
        copyto!(buf, sum_s)
        for d in lms_positions
            d == n + 1 && continue
            c = s[d]
            buf[c] += 1
            sa[buf[c]] = d
        end
        copyto!(buf, sum_l)
        let c = s[n]
            buf[c] += 1
            sa[buf[c]] = n
        end
        for i in 1:n
            v = sa[i]
            if v >= 2 && !ls[v-1]
                c = s[v-1]
                buf[c] += 1
                sa[buf[c]] = v - 1
            end
        end
        copyto!(buf, sum_l)
        for i in n:-1:1
            v = sa[i]
            if v >= 2 && ls[v-1]
                c = s[v-1] + 1
                sa[buf[c]] = v - 1
                buf[c] -= 1
            end
        end
    end

    # LMS(= 直前が L 型で自身が S 型)の位置
    lms_map = zeros(Int, n + 1)
    m = 0
    for i in 2:n
        if !ls[i-1] && ls[i]
            m += 1
            lms_map[i] = m
        end
    end
    lms = Vector{Int}(undef, m)
    let j = 0
        for i in 2:n
            if !ls[i-1] && ls[i]
                j += 1
                lms[j] = i
            end
        end
    end

    induce!(lms)

    if m > 0
        sorted_lms = Vector{Int}(undef, m)
        let j = 0
            for v in sa
                if lms_map[v] != 0
                    j += 1
                    sorted_lms[j] = v
                end
            end
        end
        # LMS 部分文字列に名前(1..rec_upper)を付けて再帰
        rec_s = Vector{Int}(undef, m)
        rec_upper = 1
        rec_s[lms_map[sorted_lms[1]]] = 1
        for i in 2:m
            l, r = sorted_lms[i-1], sorted_lms[i]
            end_l = lms_map[l] + 1 <= m ? lms[lms_map[l]+1] : n + 1
            end_r = lms_map[r] + 1 <= m ? lms[lms_map[r]+1] : n + 1
            same = true
            if end_l - l != end_r - r
                same = false
            else
                while l < end_l
                    s[l] != s[r] && break
                    l += 1
                    r += 1
                end
                if l == n + 1 || r == n + 1 || s[l] != s[r]
                    same = false
                end
            end
            same || (rec_upper += 1)
            rec_s[lms_map[sorted_lms[i]]] = rec_upper
        end

        rec_sa = _sa_is(rec_s, rec_upper)

        for i in 1:m
            sorted_lms[i] = lms[rec_sa[i]]
        end
        induce!(sorted_lms)
    end
    return sa
end

"""
    suffix_array(s::AbstractString) -> Vector{Int}
    suffix_array(v::AbstractVector{<:Integer}, upper::Integer) -> Vector{Int}
    suffix_array(v::AbstractVector) -> Vector{Int}

接尾辞配列を返す。返り値 `sa` は長さ `n` で、**1-indexed** の開始位置の列。
`sa[i]` は辞書順で `i` 番目に小さい接尾辞の開始位置(接尾辞は `s[sa[i]:end]`)。

- 文字列版:codeunits(バイト列)ベースで比較する(非 ASCII を含んでもよい。
  開始位置はバイト単位)。計算量 O(n)
- `(v, upper)` 版:`0 ≤ v[i] ≤ upper` を要求する(C++ 版と同じく値域は 0 起点のまま)。
  計算量 O(n + upper)
- 1 引数のベクタ版:要素は `<` で比較可能であればよい。座標圧縮してから
  SA-IS にかける。計算量 O(n log n)

アルゴリズムは SA-IS(線形時間)。
"""
function suffix_array(s::AbstractString)
    return _sa_is([Int(c) + 1 for c in codeunits(s)], 256)
end

function suffix_array(v::AbstractVector{<:Integer}, upper::Integer)
    upper >= 0 || throw(ArgumentError("upper は非負である必要があります"))
    all(x -> 0 <= x <= upper, v) ||
        throw(ArgumentError("すべての要素が 0 ≤ v[i] ≤ upper を満たす必要があります"))
    return _sa_is([Int(x) + 1 for x in v], Int(upper) + 1)
end

function suffix_array(v::AbstractVector)
    n = length(v)
    idx = sortperm(collect(v))
    s2 = Vector{Int}(undef, n)
    now = 1
    for i in 1:n
        i > 1 && v[idx[i-1]] != v[idx[i]] && (now += 1)
        s2[idx[i]] = now
    end
    return _sa_is(s2, now)
end

"""
    lcp_array(s, sa::AbstractVector{<:Integer}) -> Vector{Int}

接尾辞配列 `sa`([`suffix_array`](@ref) の返り値、1-indexed)から LCP 配列を返す。
返り値は長さ `n - 1` で、`lcp[i]` は接尾辞 `s[sa[i]:end]` と `s[sa[i+1]:end]` の
最長共通接頭辞の長さ。`s` は `AbstractString`(codeunits ベース)/ `AbstractVector`
の両対応。`n ≥ 1` を要求する。計算量 O(n)。

参考: T. Kasai, G. Lee, H. Arimura, S. Arikawa, and K. Park,
Linear-Time Longest-Common-Prefix Computation in Suffix Arrays and Its Applications
"""
function lcp_array(s::AbstractVector, sa::AbstractVector{<:Integer})
    n = length(s)
    n >= 1 || throw(ArgumentError("lcp_array には長さ 1 以上の列が必要です"))
    rnk = Vector{Int}(undef, n)
    for i in 1:n
        rnk[sa[i]] = i
    end
    lcp = zeros(Int, n - 1)
    h = 0
    for i in 1:n
        h > 0 && (h -= 1)
        rnk[i] == 1 && continue
        j = sa[rnk[i]-1]
        while j + h <= n && i + h <= n
            s[j+h] != s[i+h] && break
            h += 1
        end
        lcp[rnk[i]-1] = h
    end
    return lcp
end

lcp_array(s::AbstractString, sa::AbstractVector{<:Integer}) =
    lcp_array(collect(codeunits(s)), sa)

"""
    z_algorithm(s) -> Vector{Int}

Z 配列を返す。返り値は長さ `n` で、`z[i]` は `s` 全体と接尾辞 `s[i:end]` の
最長共通接頭辞の長さ(規約として `z[1] = n`。C++ 版の `z[0] = n` に対応)。
`s` は `AbstractString`(codeunits ベース)/ `AbstractVector` の両対応。計算量 O(n)。

参考: D. Gusfield,
Algorithms on Strings, Trees, and Sequences
"""
function z_algorithm(s::AbstractVector)
    n = length(s)
    n == 0 && return Int[]
    z = zeros(Int, n)
    j = 1
    for i in 2:n
        k = j + z[j] <= i ? 0 : min(j + z[j] - i, z[i-j+1])
        while i + k <= n && s[k+1] == s[i+k]
            k += 1
        end
        z[i] = k
        j + z[j] < i + z[i] && (j = i)
    end
    z[1] = n
    return z
end

z_algorithm(s::AbstractString) = z_algorithm(collect(codeunits(s)))
