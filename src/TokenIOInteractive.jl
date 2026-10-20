# ============================================================
# tokeniointeractive.jl — トークン逐次読み【インタラクティブ問題用】
# ------------------------------------------------------------
# 非インタラクティブ用 tokenio.jl と同じ記法で読める (同名 API なので併用は不可):
#   function main()
#       N = nextI()
#       while ...
#           println("? ", l, " ", r)   # クエリ出力 (flush は書かなくてよい)
#           ans = nextS()              # 読む前に自動で flush(stdout) → 1行読み足し
#           ...
#       end
#       println("! ", answer)          # 最後の出力はプロセス終了時に flush される
#   end
# 特徴:
#   - stdin は行単位の遅延読み (全読みしない) → EOF を待たずジャッジと交互にやり取りできる
#   - next* はバッファが尽きたときだけ flush(stdout) してから readline する
#     (C++ で cin が cout に tie されているのと同じ動き) → 明示 flush は不要
#   - @input も使える。input!() は互換のための no-op
#   - 非インタラクティブ問題でも動くが、全読み版 (tokenio.jl) の方が速い
# ============================================================

const _IN = Ref("")
const _POS = Ref(1)

input!() = nothing   # 互換 no-op (インタラクティブでは全読みしない)

function _more!()   # 次の 1 行をバッファへ。EOF なら false
    flush(stdout)   # 溜まっているクエリを必ず届けてから応答を待つ
    eof(stdin) && return false
    _IN[] = readline(stdin); _POS[] = 1
    return true
end

@inline function _skiptok!()   # 次のトークン先頭までカーソルを進める。EOF なら false
    s = _IN[]; n = ncodeunits(s); p = _POS[]
    while true
        @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end
        if p <= n
            _POS[] = p
            return true
        end
        _more!() || (_POS[] = p; return false)
        s = _IN[]; n = ncodeunits(s); p = _POS[]
    end
end

function nextI()
    _skiptok!() || return 0
    s = _IN[]; n = ncodeunits(s); p = _POS[]
    neg = false
    @inbounds if codeunit(s, p) == 0x2d  # '-'
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
    _skiptok!() || return SubString(_IN[], 1, 0)   # EOF → 空トークン
    s = _IN[]; n = ncodeunits(s); p = _POS[]
    q = p
    @inbounds while q <= n && codeunit(s, q) > 0x20; q += 1; end
    _POS[] = q
    return SubString(s, p, thisind(s, q - 1))   # thisind で UTF-8 境界に整合
end

nextF() = parse(Float64, nextS())

function nextC()   # 空白をスキップして1文字 (C++ の cin >> char 相当)
    _skiptok!() || return '\0'
    s = _IN[]; p = _POS[]
    c = s[p]
    _POS[] = nextind(s, p)
    return c
end

# ============================================================
# @input — Rust の proconio::input! に揃えた読み込みマクロ (tokenio.jl と同一)
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
