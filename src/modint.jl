"""
    ModInt{M} <: Number

法 `M` の剰余環の元。`M` は `2^31` 未満の正整数(型パラメータ)。

内部表現は C++ 版 `static_modint` と同じ `UInt32`(値域 `[0, M)`)。
`(ModInt, ModInt)` のようなノード型を大量に並べるデータ構造でメモリ幅が半分に
なり、乗算の剰余も符号なし演算になる — 競プロ用途では性能が本質なので
表現も C++ 版に揃える。

- 四則演算 `+ - * / ^`、`inv`、`zero`、`one`、`==` をサポート
- `Integer` との混合演算は自動昇格(`ModInt{7}(3) + 1 == ModInt{7}(4)`)
- `inv` / `/` は法と互いに素でない値に対して `DomainError` を投げる(`invmod` 準拠)
- 値の取り出しは [`val`](@ref)(`Int` を返す)

よく使う法にはエイリアス `ModInt998244353`、`ModInt1000000007` がある。

# 例
```julia
a = ModInt998244353(10)^18
val(a + 1)
```
"""
struct ModInt{M} <: Number
    val::UInt32
    ModInt{M}(x::Integer) where {M} = new{M}(UInt32(mod(x, M)))
    # 無検査コンストラクタ(C++ mint::raw 相当)。0 ≤ x < M は呼び出し側の責任。
    ModInt{M}(x::UInt32, ::Val{:unsafe}) where {M} = new{M}(x)
end

# ライブラリ内部用の無検査構築ヘルパー(演算結果は常に [0, M) にあるため還元不要)
_raw(::Type{ModInt{M}}, x::Integer) where {M} = ModInt{M}(x % UInt32, Val(:unsafe))

const ModInt998244353 = ModInt{998244353}
const ModInt1000000007 = ModInt{1000000007}

"""
    val(a::ModInt) -> Int

`a` の代表元(`0 ≤ val < M`)を返す。
"""
val(a::ModInt) = Int(a.val)

Base.:+(a::ModInt{M}, b::ModInt{M}) where {M} =
    (v = a.val + b.val; _raw(ModInt{M}, v >= UInt32(M) ? v - UInt32(M) : v))
Base.:-(a::ModInt{M}, b::ModInt{M}) where {M} =
    (v = a.val + UInt32(M) - b.val; _raw(ModInt{M}, v >= UInt32(M) ? v - UInt32(M) : v))
Base.:-(a::ModInt{M}) where {M} =
    _raw(ModInt{M}, a.val == 0 ? UInt32(0) : UInt32(M) - a.val)
Base.:*(a::ModInt{M}, b::ModInt{M}) where {M} =
    _raw(ModInt{M}, (UInt64(a.val) * UInt64(b.val)) % UInt64(M))
Base.inv(a::ModInt{M}) where {M} = _raw(ModInt{M}, invmod(Int(a.val), M))
Base.:/(a::ModInt{M}, b::ModInt{M}) where {M} = a * inv(b)
# powermod は負の指数も法逆元で処理する(互いに素でなければ DomainError)
Base.:^(a::ModInt{M}, n::Integer) where {M} = _raw(ModInt{M}, powermod(Int(a.val), n, M))

Base.zero(::Type{ModInt{M}}) where {M} = _raw(ModInt{M}, UInt32(0))
Base.one(::Type{ModInt{M}}) where {M} = _raw(ModInt{M}, UInt32(M == 1 ? 0 : 1))
Base.:(==)(a::ModInt{M}, b::ModInt{M}) where {M} = a.val == b.val
Base.iszero(a::ModInt) = a.val == 0
Base.isone(a::ModInt{M}) where {M} = a.val == UInt32(M == 1 ? 0 : 1)

Base.promote_rule(::Type{ModInt{M}}, ::Type{<:Integer}) where {M} = ModInt{M}
Base.convert(::Type{ModInt{M}}, x::Integer) where {M} = ModInt{M}(x)

Base.show(io::IO, a::ModInt) = print(io, val(a))
