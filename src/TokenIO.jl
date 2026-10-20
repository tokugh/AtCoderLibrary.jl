# Library: https://github.com/tokugh/AtCoderLibrary.jl
# ============================================================
# tokenio.jl — C++ スタイルのトークン逐次読み (cin >> 相当)【非インタラクティブ問題用】
# ------------------------------------------------------------
# 使い方:
#   function main()
#       N = nextI(); Q = nextI() # 次の Int を順に読む (負数対応)
#       s = nextS()              # 次のトークンを SubString で (String が要るなら String(nextS()))
#       x = nextF()              # 次の Float64
#       ...
#   end
#   初回の next* / @input が stdin を自動で全読みするので input!() は書かなくてよい
#   (呼べば強制再読み。main 冒頭で input!() する既存コードもそのまま動く)
# 特徴:
#   - const Ref のグローバルカーソル → 型安定・クロージャボックス化なし・トークンごとのアロケ 0
#     (nextS だけ SubString 1個 = 16B。中身のコピーはしない)
#   - 全読み済みかどうかは「今の stdin オブジェクトから読んだか」(objectid) で判定。
#     atcpkg テンプレ (webgen/wrap) の stdin シャドーイングとそのまま互換:
#     precompile ワークロードはサンプルごとに stdin を別 IOStream に差し替える
#     → サンプル境界で自動再読み。実行時も焼き込まれた objectid は本物の stdin と
#     一致しないため必ず読み直す (IOStream 参照ではなく UInt を持つので焼き込みも安全)
#   - インタラクティブ問題では使えない (EOF まで全読みしようとしてジャッジと
#     デッドロックする)。TokenIOInteractive.jl を使うこと
# ============================================================

const _IN = Ref("")
const _POS = Ref(1)
const _SRC = Ref(UInt(0))   # _IN の読み込み元 stdin の objectid (0 = 未読)

input!() = (_IN[] = read(stdin, String); _POS[] = 1; _SRC[] = objectid(stdin); nothing)
@inline _ensure!() = (_SRC[] == objectid(stdin) || input!(); nothing)

@inline function nextI()
    _ensure!()
    s = _IN[]; n = ncodeunits(s); p = _POS[]
    @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end
    neg = false
    @inbounds if p <= n && codeunit(s, p) == 0x2d  # '-'
        neg = true; p += 1
    end
    x = 0
    @inbounds while p <= n
        c = codeunit(s, p)
        (0x30 <= c <= 0x39) || break
        x = 10x + Int(c - 0x30); p += 1
    end
    _POS[] = p
    return neg ? -x : x
end

function nextS()
    _ensure!()
    s = _IN[]; n = ncodeunits(s); p = _POS[]
    @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end
    p > n && return SubString(s, 1, 0)   # EOF → 空トークン
    q = p
    @inbounds while q <= n && codeunit(s, q) > 0x20; q += 1; end
    _POS[] = q
    return SubString(s, p, thisind(s, q - 1))   # thisind で UTF-8 境界に整合
end

nextF() = parse(Float64, nextS())

function nextC()   # 空白をスキップして1文字 (C++ の cin >> char 相当)
    _ensure!()
    s = _IN[]; n = ncodeunits(s); p = _POS[]
    @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end
    p > n && return '\0'
    c = s[p]
    _POS[] = nextind(s, p)
    return c
end

# ============================================================
# @input — Rust の proconio::input! に揃えた読み込みマクロ
#   @input N::Int Q::Int            # input! { n: usize, q: usize }
#   @input A::[Int, N]              # a: [i64; n]   (長さに直前の変数を使える)
#   @input G::[[Int, M], N]         # ネスト可 (N 本の長さ M 配列)
#   @input begin                    # ブロック形式も可
#       N::Int; Q::Int
#       A::[Int, N]
#   end
# 対応型: Int系 / Float系 / String / SubString / Char (他は parse(T, token))
# 左から順に評価されるので、後続の長さ式に前の変数を使える。
# ============================================================

@inline _next(::Type{Int})               = nextI()
@inline _next(::Type{T}) where {T<:Integer} = T(nextI())
@inline _next(::Type{Float64})           = nextF()
@inline _next(::Type{T}) where {T<:AbstractFloat} = parse(T, nextS())
@inline _next(::Type{String})            = String(nextS())
@inline _next(::Type{SubString{String}}) = nextS()
@inline _next(::Type{Char})              = nextC()
@inline _next(::Type{T}) where {T}       = parse(T, nextS())

function _input_expr(T)
    if T isa Expr && T.head === :vect            # [要素, 長さ]
        length(T.args) == 2 || error("@input: 配列は [型, 長さ] で指定してください (got: $T)")
        elem, len = T.args
        return :([$(_input_expr(elem)) for _ in 1:$(esc(len))])
    else
        return :(_next($(esc(T))))
    end
end

macro input(args...)
    items = Any[]
    for a in args
        if a isa Expr && a.head === :block       # begin ... end 形式
            append!(items, filter(x -> !(x isa LineNumberNode), a.args))
        else
            push!(items, a)
        end
    end
    stmts = Any[]
    for v in items
        v isa Expr && v.head === :(::) || error("@input: 変数::型 で指定してください (got: $v)")
        name, T = v.args
        push!(stmts, :($(esc(name)) = $(_input_expr(T))))
    end
    Expr(:block, stmts..., nothing)
end
