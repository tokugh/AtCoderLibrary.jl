# Library: https://github.com/tokugh/AtCoderLibrary.jl
# convolution.jl — NTT(数論変換)による畳み込み
#
# C++ 版 ACL convolution.hpp の移植。内部の butterfly / butterfly_inv は
# C++ 版と同じ radix-4 主体・遅延剰余(UInt64 演算)のアルゴリズム。
# 内部ループは 0-indexed の論理添え字で書き、配列アクセス時のみ +1 する。

# ceil(log2(n)) 相当(n ≥ 0)。C++ internal::ceil_pow2 と同じ。
_conv_ceil_pow2(n::Int) = n <= 1 ? 0 : 64 - leading_zeros(n - 1)

# C++ internal::primitive_root_constexpr の移植。m は素数前提。
function _conv_primitive_root(m::Int64)
    m == 2 && return Int64(1)
    m == 167772161 && return Int64(3)
    m == 469762049 && return Int64(3)
    m == 754974721 && return Int64(11)
    m == 998244353 && return Int64(3)
    divs = Int64[2]
    x = (m - 1) ÷ 2
    while x % 2 == 0
        x ÷= 2
    end
    i = Int64(3)
    while i * i <= x
        if x % i == 0
            push!(divs, i)
            while x % i == 0
                x ÷= i
            end
        end
        i += 2
    end
    x > 1 && push!(divs, x)
    g = Int64(2)
    while true
        # g はループ末尾で再代入されるため、クロージャに直接捕捉させるとボックス化
        # されて戻り値が Any に広がる。let で束縛を固定する(_sa_doubling と同じ)
        ok = let g = g
            all(d -> powermod(g, (m - 1) ÷ d, m) != 1, divs)
        end
        ok && return g
        g += 1
    end
end

# C++ internal::fft_info の移植。値はすべて mod M の代表元(Int64)で持つ。
# 配列は 0-indexed の論理添え字 i を Julia 添え字 i+1 に対応させる。
struct _ConvFFTInfo
    rank2::Int          # M - 1 が 2 で割り切れる回数
    root::Vector{Int64}   # root[i+1]^(2^i) == 1
    iroot::Vector{Int64}
    rate2::Vector{Int64}
    irate2::Vector{Int64}
    rate3::Vector{Int64}
    irate3::Vector{Int64}
end

function _ConvFFTInfo(M::Int64)
    g = _conv_primitive_root(M)
    rank2 = trailing_zeros(M - 1)
    root = Vector{Int64}(undef, rank2 + 1)
    iroot = Vector{Int64}(undef, rank2 + 1)
    root[rank2 + 1] = powermod(g, (M - 1) >> rank2, M)
    iroot[rank2 + 1] = invmod(root[rank2 + 1], M)
    for i in rank2-1:-1:0
        root[i + 1] = mod(root[i + 2] * root[i + 2], M)
        iroot[i + 1] = mod(iroot[i + 2] * iroot[i + 2], M)
    end
    rate2 = Vector{Int64}(undef, max(0, rank2 - 1))
    irate2 = Vector{Int64}(undef, max(0, rank2 - 1))
    let prod = Int64(1), iprod = Int64(1)
        for i in 0:rank2-2
            rate2[i + 1] = mod(root[i + 3] * prod, M)
            irate2[i + 1] = mod(iroot[i + 3] * iprod, M)
            prod = mod(prod * iroot[i + 3], M)
            iprod = mod(iprod * root[i + 3], M)
        end
    end
    rate3 = Vector{Int64}(undef, max(0, rank2 - 2))
    irate3 = Vector{Int64}(undef, max(0, rank2 - 2))
    let prod = Int64(1), iprod = Int64(1)
        for i in 0:rank2-3
            rate3[i + 1] = mod(root[i + 4] * prod, M)
            irate3[i + 1] = mod(iroot[i + 4] * iprod, M)
            prod = mod(prod * iroot[i + 4], M)
            iprod = mod(iprod * root[i + 4], M)
        end
    end
    _ConvFFTInfo(rank2, root, iroot, rate2, irate2, rate3, irate3)
end

const _CONV_FFT_CACHE = Dict{Int64, _ConvFFTInfo}()

_conv_fft_info(M::Int64) = get!(() -> _ConvFFTInfo(M), _CONV_FFT_CACHE, M)

# C++ internal::butterfly の移植。a は mod M の代表元の列(長さは 2 冪)。
# - M は Val で型レベル定数として受ける:ループ内の `% M` がコンパイル時に
#   逆数乗算(バレットリダクション相当)へ定数畳み込みされ、除算命令が消える
# - バッファは C++ 版 mint 配列と同じ UInt32(Int64 の半分のメモリ帯域)
function _butterfly!(a::Vector{UInt32}, ::Val{M}, info::_ConvFFTInfo) where {M}
    n = length(a)
    h = _conv_ceil_pow2(n)
    uM = UInt64(M)
    uM32 = UInt32(M)
    len = 0  # a[i, i+(n>>len), i+2*(n>>len), ..] が変換済み
    @inbounds while len < h
        if h - len == 1
            p = 1 << (h - len - 1)
            rot = Int64(1)
            for s in 0:(1 << len)-1
                urot = UInt64(rot)
                offset = s << (h - len)
                for i in 0:p-1
                    l = a[i + offset + 1]
                    r = ((UInt64(a[i + offset + p + 1]) * urot) % uM) % UInt32
                    a[i + offset + 1] = (v = l + r; v >= uM32 ? v - uM32 : v)
                    a[i + offset + p + 1] = (v = l + uM32 - r; v >= uM32 ? v - uM32 : v)
                end
                if s + 1 != (1 << len)
                    rot = mod(rot * info.rate2[trailing_ones(s) + 1], M)
                end
            end
            len += 1
        else
            # radix-4
            p = 1 << (h - len - 2)
            rot = Int64(1)
            imag = UInt64(info.root[3])  # root[2] (0-indexed)
            mod2 = uM * uM
            for s in 0:(1 << len)-1
                rot2 = mod(rot * rot, M)
                rot3 = mod(rot2 * rot, M)
                urot = UInt64(rot); urot2 = UInt64(rot2); urot3 = UInt64(rot3)
                offset = s << (h - len)
                for i in 0:p-1
                    a0 = UInt64(a[i + offset + 1])
                    a1 = UInt64(a[i + offset + p + 1]) * urot
                    a2 = UInt64(a[i + offset + 2p + 1]) * urot2
                    a3 = UInt64(a[i + offset + 3p + 1]) * urot3
                    a1na3imag = ((a1 + mod2 - a3) % uM) * imag
                    na2 = mod2 - a2
                    a[i + offset + 1] = ((a0 + a2 + a1 + a3) % uM) % UInt32
                    a[i + offset + p + 1] = ((a0 + a2 + (2mod2 - (a1 + a3))) % uM) % UInt32
                    a[i + offset + 2p + 1] = ((a0 + na2 + a1na3imag) % uM) % UInt32
                    a[i + offset + 3p + 1] = ((a0 + na2 + (mod2 - a1na3imag)) % uM) % UInt32
                end
                if s + 1 != (1 << len)
                    rot = mod(rot * info.rate3[trailing_ones(s) + 1], M)
                end
            end
            len += 2
        end
    end
    a
end

# C++ internal::butterfly_inv の移植。M の受け方・バッファは _butterfly! と同じ。
function _butterfly_inv!(a::Vector{UInt32}, ::Val{M}, info::_ConvFFTInfo) where {M}
    n = length(a)
    h = _conv_ceil_pow2(n)
    uM = UInt64(M)
    uM32 = UInt32(M)
    len = h  # a[i, i+(n>>len), i+2*(n>>len), ..] が変換済み
    @inbounds while len > 0
        if len == 1
            p = 1 << (h - len)
            irot = Int64(1)
            for s in 0:(1 << (len - 1))-1
                uirot = UInt64(irot)
                offset = s << (h - len + 1)
                for i in 0:p-1
                    l = a[i + offset + 1]
                    r = a[i + offset + p + 1]
                    a[i + offset + 1] = (v = l + r; v >= uM32 ? v - uM32 : v)
                    a[i + offset + p + 1] =
                        (((UInt64(l) + uM - r) * uirot) % uM) % UInt32
                end
                if s + 1 != (1 << (len - 1))
                    irot = mod(irot * info.irate2[trailing_ones(s) + 1], M)
                end
            end
            len -= 1
        else
            # radix-4
            p = 1 << (h - len)
            irot = Int64(1)
            iimag = UInt64(info.iroot[3])  # iroot[2] (0-indexed)
            for s in 0:(1 << (len - 2))-1
                irot2 = mod(irot * irot, M)
                irot3 = mod(irot2 * irot, M)
                uirot = UInt64(irot); uirot2 = UInt64(irot2); uirot3 = UInt64(irot3)
                offset = s << (h - len + 2)
                for i in 0:p-1
                    a0 = UInt64(a[i + offset + 1])
                    a1 = UInt64(a[i + offset + p + 1])
                    a2 = UInt64(a[i + offset + 2p + 1])
                    a3 = UInt64(a[i + offset + 3p + 1])
                    a2na3iimag = ((uM + a2 - a3) * iimag) % uM
                    a[i + offset + 1] = ((a0 + a1 + a2 + a3) % uM) % UInt32
                    a[i + offset + p + 1] =
                        (((a0 + (uM - a1) + a2na3iimag) * uirot) % uM) % UInt32
                    a[i + offset + 2p + 1] =
                        (((a0 + a1 + (uM - a2) + (uM - a3)) * uirot2) % uM) % UInt32
                    a[i + offset + 3p + 1] =
                        (((a0 + (uM - a1) + (uM - a2na3iimag)) * uirot3) % uM) % UInt32
                end
                if s + 1 != (1 << (len - 2))
                    irot = mod(irot * info.irate3[trailing_ones(s) + 1], M)
                end
            end
            len -= 2
        end
    end
    a
end

# ナイーブ O(nm) 畳み込み(C++ internal::convolution_naive の移植)
function _conv_naive(a::AbstractVector{ModInt{M}}, b::AbstractVector{ModInt{M}}) where {M}
    n, m = length(a), length(b)
    ans = fill(zero(ModInt{M}), n + m - 1)
    if n < m
        for j in 1:m, i in 1:n
            ans[i + j - 1] += a[i] * b[j]
        end
    else
        for i in 1:n, j in 1:m
            ans[i + j - 1] += a[i] * b[j]
        end
    end
    ans
end

# FFT ベースの畳み込み(C++ internal::convolution_fft の移植)
function _conv_fft(a::AbstractVector{ModInt{M}}, b::AbstractVector{ModInt{M}}) where {M}
    n, m = length(a), length(b)
    h = _conv_ceil_pow2(n + m - 1)
    z = 1 << h
    info = _conv_fft_info(Int64(M))
    h <= info.rank2 || throw(ArgumentError(
        "法 $M は長さ $(n + m - 1) の畳み込みに必要な 2^$h 乗根を持ちません(NTT-friendly な素数を使ってください)"))
    va = zeros(UInt32, z); vb = zeros(UInt32, z)
    for i in 1:n; va[i] = a[i].val; end
    for i in 1:m; vb[i] = b[i].val; end
    _butterfly!(va, Val(Int64(M)), info)
    _butterfly!(vb, Val(Int64(M)), info)
    uM = UInt64(M)
    @inbounds for i in 1:z
        va[i] = ((UInt64(va[i]) * UInt64(vb[i])) % uM) % UInt32
    end
    _butterfly_inv!(va, Val(Int64(M)), info)
    uiz = UInt64(invmod(Int64(z), Int64(M)))
    c = Vector{ModInt{M}}(undef, n + m - 1)
    @inbounds for i in 1:(n + m - 1)
        c[i] = _raw(ModInt{M}, (UInt64(va[i]) * uiz) % uM)
    end
    c
end

"""
    convolution(a::AbstractVector{ModInt{M}}, b::AbstractVector{ModInt{M}}) -> Vector{ModInt{M}}

`a` と `b` の畳み込み ``c_k = \\sum_{i+j-1=k} a_i b_j`` を mod `M` で計算する
(添え字は 1-indexed、返り値の長さは `length(a) + length(b) - 1`)。
どちらかが空なら空を返す。

`M` は素数で、必要な変換長 `z`(`length(a) + length(b) - 1` 以上の最小の 2 冪)に対し
`z | M - 1` を満たす必要がある(998244353 など NTT-friendly な素数)。
条件を満たさない場合は `ArgumentError`(短い入力はナイーブ計算に落ちるためエラーにならない)。

計算量: O((n + m) log(n + m))
"""
function convolution(a::AbstractVector{ModInt{M}}, b::AbstractVector{ModInt{M}}) where {M}
    n, m = length(a), length(b)
    (n == 0 || m == 0) && return ModInt{M}[]
    min(n, m) <= 60 && return _conv_naive(a, b)
    _conv_fft(a, b)
end

"""
    convolution(m::Integer, a::AbstractVector{<:Integer}, b::AbstractVector{<:Integer}) -> Vector{Int64}

整数列 `a`, `b` の畳み込みを mod `m` で計算する(C++ 版 `convolution<mod>` 相当)。
要素は内部で `ModInt{m}` に変換される(負数も可)。返り値は代表元(`0 ≤ c < m`)の列。

`m` の条件は `ModInt` 版と同じ: 素数で、必要な変換長 `z` に対し `z | m - 1` を
満たす必要がある(998244353 など NTT-friendly な素数)。条件を満たさない場合は
`ArgumentError`(短い入力はナイーブ計算に落ちるためエラーにならない)。
"""
Base.@constprop :aggressive function convolution(m::Integer, a::AbstractVector{<:Integer},
                                                 b::AbstractVector{<:Integer})::Vector{Int64}
    # :aggressive 指定は、m がリテラル定数で呼ばれた場合に ModInt{Int(m)} まで定数伝播
    # させるため。戻り値注釈で戻り値型が定数なしでも確定しているため、既定のヒューリス
    # ティックでは伝播が省略され、precompile 時の静的推論が内部の NTT まで届かない
    (isempty(a) || isempty(b)) && return Int64[]
    _convolution_mod(ModInt{Int(m)}, a, b)
end

# 関数バリア: 上の convolution(m, a, b) では ModInt{Int(m)} が実行時の値に依存する
# 型のため型不安定になる。型パラメータで受け直すここから先は型安定に実行され、
# 外側の戻り値注釈 ::Vector{Int64} が呼び出し元への Any の伝播を断つ
function _convolution_mod(::Type{Mint}, a::AbstractVector{<:Integer},
                          b::AbstractVector{<:Integer}) where {Mint<:ModInt}
    val.(convolution(Mint.(a), Mint.(b)))
end

"""
    convolution_ll(a::AbstractVector{<:Integer}, b::AbstractVector{<:Integer}) -> Vector{Int64}

整数列 `a`, `b` の畳み込みを `Int64` の正確な値で計算する
(C++ 版 `convolution_ll` の移植。3 つの NTT 素数での畳み込みを CRT で復元する)。

制約: 結果の各要素が `Int64` に収まること(``|c_k| < 2^{63}``)。
"""
function convolution_ll(a::AbstractVector{<:Integer}, b::AbstractVector{<:Integer})
    n, m = length(a), length(b)
    (n == 0 || m == 0) && return Int64[]

    MOD1 = UInt64(754974721)  # 2^24 | MOD1 - 1
    MOD2 = UInt64(167772161)  # 2^25 | MOD2 - 1
    MOD3 = UInt64(469762049)  # 2^26 | MOD3 - 1
    M2M3 = MOD2 * MOD3
    M1M3 = MOD1 * MOD3
    M1M2 = MOD1 * MOD2
    M1M2M3 = MOD1 * MOD2 * MOD3  # mod 2^64 で意図的にオーバーフロー

    i1 = UInt64(invmod(Int64(M2M3 % MOD1), Int64(MOD1)))
    i2 = UInt64(invmod(Int64(M1M3 % MOD2), Int64(MOD2)))
    i3 = UInt64(invmod(Int64(M1M2 % MOD3), Int64(MOD3)))

    c1 = convolution(Int64(MOD1), a, b)
    c2 = convolution(Int64(MOD2), a, b)
    c3 = convolution(Int64(MOD3), a, b)

    offset = (UInt64(0), UInt64(0), M1M2M3, 2 * M1M2M3, 3 * M1M2M3)
    c = Vector{Int64}(undef, n + m - 1)
    @inbounds for i in 1:(n + m - 1)
        x = UInt64(0)
        x += (UInt64(c1[i]) * i1) % MOD1 * M2M3
        x += (UInt64(c2[i]) * i2) % MOD2 * M1M3
        x += (UInt64(c3[i]) * i3) % MOD3 * M1M2
        # x は真の値 r に対し r + k * M1M2M3 (mod 2^64)。c1[i] との mod MOD1 の
        # ずれから k ∈ {0,1,2,3} を特定して引き戻す(C++ 版のコメント参照)
        diff = c1[i] - mod(x % Int64, Int64(MOD1))
        diff < 0 && (diff += Int64(MOD1))
        x -= offset[diff % 5 + 1]
        c[i] = x % Int64
    end
    c
end
