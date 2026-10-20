# ==== 入力(TokenIO ワンライナー版)====
const _IN = Ref(""); const _POS = Ref(1)
input!() = (_IN[] = read(stdin, String); _POS[] = 1; nothing)
@inline function nextI(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; neg = false; @inbounds if p <= n && codeunit(s, p) == 0x2d; neg = true; p += 1; end; x = 0; @inbounds while p <= n; c = codeunit(s, p); (0x30 <= c <= 0x39) || break; x = 10x + Int(c - 0x30); p += 1; end; _POS[] = p; return neg ? -x : x; end
@inline function nextS(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; p > n && return SubString(s, 1, 0); q = p; @inbounds while q <= n && codeunit(s, q) > 0x20; q += 1; end; _POS[] = q; return SubString(s, p, thisind(s, q - 1)); end
nextF() = parse(Float64, nextS())
function nextC(); s = _IN[]; n = ncodeunits(s); p = _POS[]; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; p > n && return '\0'; c = s[p]; _POS[] = nextind(s, p); return c; end

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

# ==== ライブラリ: math.jl ====
# ACL math.hpp の移植。数論的関数群(pow_mod / inv_mod / crt / floor_sum)。

"""
    pow_mod(x::Integer, n::Integer, m::Integer) -> Int64

`x^n mod m` を返す(`0 ≤ 返り値 < m`)。

制約: `n ≥ 0`, `1 ≤ m`。`x` は負でもよい。`m == 1` のときは常に 0。
"""
function pow_mod(x::Integer, n::Integer, m::Integer)::Int64
    n >= 0 || throw(DomainError(n, "n は非負である必要があります"))
    m >= 1 || throw(DomainError(m, "m は 1 以上である必要があります"))
    m == 1 && return 0
    powermod(Int64(x), n, Int64(m))
end

"""
    inv_mod(x::Integer, m::Integer) -> Int64

`x * y ≡ 1 (mod m)` を満たす `y`(`0 ≤ y < m`)を返す。

制約: `1 ≤ m`, `gcd(x, m) == 1`(違反時は `DomainError`)。
"""
function inv_mod(x::Integer, m::Integer)::Int64
    m >= 1 || throw(DomainError(m, "m は 1 以上である必要があります"))
    m == 1 && return 0
    invmod(Int64(mod(x, m)), Int64(m))
end

# 拡張ユークリッド互除法。b ≥ 1 に対し (g, x) を返す:
# g = gcd(a, b)、x*a ≡ g (mod b)、0 ≤ x < b/g
function _inv_gcd(a::Int64, b::Int64)
    a = mod(a, b)
    a == 0 && return (b, Int64(0))
    s, t = b, a
    m0, m1 = Int64(0), Int64(1)
    while t != 0
        u = s ÷ t
        s -= t * u
        m0 -= m1 * u
        s, t = t, s
        m0, m1 = m1, m0
    end
    m0 < 0 && (m0 += b ÷ s)
    (s, m0)
end

"""
    crt(r::AbstractVector{<:Integer}, m::AbstractVector{<:Integer}) -> (Int64, Int64)

中国剰余定理。連立合同式 `x ≡ r[i] (mod m[i])` を解く。

解が存在すれば `x ≡ y (mod z)`(`z = lcm(m)`)の形で表せるので、
その `(y, z)`(`0 ≤ y < z`)を返す。解がなければ `(0, 0)`。
入力が空のときは `(0, 1)`。

制約: `length(r) == length(m)`、各 `m[i] ≥ 1`、`lcm(m)` が `Int64` に収まること。
"""
function crt(r::AbstractVector{<:Integer}, m::AbstractVector{<:Integer})
    length(r) == length(m) ||
        throw(ArgumentError("r と m の長さが一致していません"))
    r0, m0 = Int64(0), Int64(1)
    for i in eachindex(r, m)
        m[i] >= 1 || throw(DomainError(m[i], "法は 1 以上である必要があります"))
        r1, m1 = Int64(mod(r[i], m[i])), Int64(m[i])
        if m0 < m1
            r0, r1 = r1, r0
            m0, m1 = m1, m0
        end
        if m0 % m1 == 0
            r0 % m1 != r1 && return (Int64(0), Int64(0))
            continue
        end
        # (r0 mod m0) ∧ (r1 mod m1) を (r2 mod lcm(m0, m1)) に合成する
        g, im = _inv_gcd(m0, m1)
        u1 = m1 ÷ g
        (r1 - r0) % g != 0 && return (Int64(0), Int64(0))
        x = (r1 - r0) ÷ g % u1 * im % u1
        r0 += x * m0
        m0 *= u1
        r0 < 0 && (r0 += m0)
    end
    (r0, m0)
end

# n < 2^32, 1 ≤ m < 2^32 に対する Σ_{i=0}^{n-1} floor((a*i + b) / m) (mod 2^64)。
# a, b は非負に正規化済みであること。
function _floor_sum_unsigned(n::UInt64, m::UInt64, a::UInt64, b::UInt64)
    ans = UInt64(0)
    while true
        if a >= m
            ans += n * (n - 1) ÷ 2 * (a ÷ m)
            a %= m
        end
        if b >= m
            ans += n * (b ÷ m)
            b %= m
        end
        y_max = a * n + b
        y_max < m && break
        n = y_max ÷ m
        b = y_max % m
        m, a = a, m
    end
    ans
end

"""
    floor_sum(n::Integer, m::Integer, a::Integer, b::Integer) -> Int64

``\\sum_{i=0}^{n-1} \\left\\lfloor \\frac{a \\times i + b}{m} \\right\\rfloor`` を返す。

これは数式(`i` は 0 起点の総和変数)であり配列の添え字ではないため、
ライブラリの 1-indexed 規約の対象外。C++ 版と同一の意味論。

制約: `0 ≤ n < 2^32`, `1 ≤ m < 2^32`。`a`, `b` は負でもよい(`Int64` の範囲内)。
答えは `Int64` に収まることを仮定する。計算量 O(log m)。
"""
function floor_sum(n::Integer, m::Integer, a::Integer, b::Integer)::Int64
    n = Int64(n); m = Int64(m); a = Int64(a); b = Int64(b)
    (0 <= n < Int64(1) << 32) || throw(DomainError(n, "0 ≤ n < 2^32 が必要です"))
    (1 <= m < Int64(1) << 32) || throw(DomainError(m, "1 ≤ m < 2^32 が必要です"))
    ans = UInt64(0)
    # a, b を非負に正規化し、差分を(mod 2^64 で)先に引いておく
    if a < 0
        a2 = mod(a, m)
        # n * (n - 1) は n が √2^63 ≈ 3.04e9 を超えると Int64 を溢れるため UInt64 で
        # 計算する(C++ 版の 1ULL * n * (n - 1) 相当。n = 0 は 0 との積になり安全)
        ans -= (UInt64(n) * (UInt64(n) - 1) ÷ 2) * ((UInt64(a2) - reinterpret(UInt64, a)) ÷ UInt64(m))
        a = a2
    end
    if b < 0
        b2 = mod(b, m)
        ans -= UInt64(n) * ((UInt64(b2) - reinterpret(UInt64, b)) ÷ UInt64(m))
        b = b2
    end
    ans += _floor_sum_unsigned(UInt64(n), UInt64(m), UInt64(a), UInt64(b))
    reinterpret(Int64, ans)
end
