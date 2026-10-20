# AtCoderLibrary.jl

[AtCoder Library (ACL)](https://github.com/atcoder/ac-library) の Julia 移植。

## すぐに使う

### 提出コードに貼る(AtCoder 本番向け)

1. [`src/`](src/) から必要なモジュールのファイルを開き、**中身を丸ごと**提出コードに貼る
2. 依存があるものは一緒に貼る:`convolution.jl` → `modint.jl`、`twosat.jl` → `scc.jl`
3. 各ファイル 1 行目のリポジトリへのリンクも消さずに残す
   (AtCoder の[生成 AI 利用ルール](https://info.atcoder.jp/entry/llm-rules-ja)上の出典表記を兼ねる)

添え字は **1-indexed・閉区間**。0-indexed の入力は読み込み時に `+ 1` する。

### 用例を見る

[AtCoder Library Practice Contest](https://atcoder.jp/contests/practice2) A〜L の解答例:

- [`practice/submit/`](practice/submit/) … ライブラリを貼り込み済みの**そのまま提出できる**ファイル(`a.jl`〜`l.jl`)
- [`practice/`](practice/) … `using AtCoderLibrary` で書いた版(手元実行用)

| 問題 | モジュール | 問題 | モジュール |
|---|---|---|---|
| [A](practice/submit/a.jl) | dsu | [G](practice/submit/g.jl) | scc |
| [B](practice/submit/b.jl) | fenwicktree | [H](practice/submit/h.jl) | twosat(+ scc) |
| [C](practice/submit/c.jl) | math(`floor_sum`) | [I](practice/submit/i.jl) | string |
| [D](practice/submit/d.jl) | maxflow | [J](practice/submit/j.jl) | segtree |
| [E](practice/submit/e.jl) | mincostflow | [K](practice/submit/k.jl) | lazysegtree(+ modint) |
| [F](practice/submit/f.jl) | convolution(+ modint) | [L](practice/submit/l.jl) | lazysegtree |

### パッケージとして入れる(手元環境向け)

```julia
using Pkg; Pkg.add(url="https://github.com/tokugh/AtCoderLibrary.jl")
using AtCoderLibrary
```

## 設計方針

設計方針の詳細は [acl-julia-design-notes.md](acl-julia-design-notes.md) を参照。要約:

| 層 | 方針 |
|---|---|
| 関数の意味論・計算量保証 | C++ 版に準拠(検証可能性のため) |
| 添え字 | 内部・外部とも 1-indexed |
| 区間 | 閉区間・inclusive(`prod(st, 2:5)` は 2 番目から 5 番目まで) |
| 代数構造の記法 | SegTree は `*` / `one`(モノイド)、FenwickTree は `+` / `zero` / `-`(可換群)をデフォルトに、演算パラメータ化で一般化 |
| 境界探索の返り値 | true 側ラベル(`searchsortedlast` 流)、空なら `max_right` は `l-1`、`min_left` は `r+1` |
| 破壊的操作 | `!` を付ける(`set!`、`add!`、`merge!`、`flow!` など) |

## モジュール一覧

| モジュール | 主な API |
|---|---|
| modint | `ModInt{M}`、`ModInt998244353`、`ModInt1000000007`、`val` |
| math | `pow_mod`、`inv_mod`、`crt`、`floor_sum` |
| dsu | `DSU`、`merge!`、`same`、`leader`、`group_size`、`groups` |
| fenwicktree | `FenwickTree`、`add!`、`sum`、`prefix`、`mult!`(一般化) |
| segtree | `SegTree`、`set!` / `st[i]=x`、`prod(st, l:r)`、`max_right`、`min_left` |
| lazysegtree | `LazySegTree`、`apply!(st, l:r, f)`、`prod`、`max_right`、`min_left` |
| string | `suffix_array`、`lcp_array`、`z_algorithm`(位置は 1-indexed) |
| convolution | `convolution`、`convolution_ll` |
| scc | `SCCGraph`、`add_edge!`、`scc` |
| twosat | `TwoSAT`、`add_clause!`、`satisfiable!`、`answer` |
| maxflow | `MFGraph`、`add_edge!`、`flow!`、`min_cut`、`get_edge`、`change_edge!` |
| mincostflow | `MCFGraph`、`add_edge!`、`flow!`、`slope!` |

## 使用例

```julia
using AtCoderLibrary

# FenwickTree(加法群がデフォルト)
ft = FenwickTree(zeros(Int, 5))
add!(ft, 2, 10)
sum(ft, 1:3)                       # 10

# SegTree(乗法記法:ラッパー型で max モノイド)
struct MaxInt x::Int end
Base.:*(a::MaxInt, b::MaxInt) = MaxInt(max(a.x, b.x))
Base.one(::Type{MaxInt}) = MaxInt(typemin(Int))
st = SegTree(MaxInt.([3, 1, 4, 1, 5]))
prod(st, 2:4).x                    # 4

# 任意演算のパラメータ化
st2 = SegTree(+, 0, [1, 2, 3, 4])
max_right(st2, 1, s -> s <= 3)     # 2(累積和が 3 以下に収まる最大位置)

# LazySegTree(区間加算・区間 min)
lst = LazySegTree(min, typemax(Int), +, +, 0, [3, 1, 4, 1, 5])
apply!(lst, 2:4, 10)
prod(lst, 1:5)                     # 3

# ModInt
val(ModInt998244353(10)^18 + 1)
```

## テスト・検証

```
julia --project=. -e 'using Pkg; Pkg.test()'
```

設計ノート §6 の合格基準に沿って三層で検証済み:

1. **ナイーブ実装とのランダム突き合わせ**(`test/`、35,000 件超)
2. **C++ 版 ACL とのランダム突き合わせ**(`verify/run.sh`、全 10 モジュール
   1,220 ケース完全一致。`max_right` は C++ と同値、`min_left` は C++ + 1、
   `suffix_array` は要素 +1 という規約どおりの対応を実測確認)
3. **AtCoder Library Practice Contest A〜L 全 12 問**(`practice/`、
   全サンプル一致。解が一意でない D/E/G/H は妥当性チェッカーで検証)

## C++ 版との対応(後方互換性の起点)

このリポジトリの範囲は **C++ 版 ACL の自然な移植**であり、それを超える機能追加は
しない(FPS などの上位レイヤーは別パッケージや提出テンプレート側に置く)。
現状の逸脱面は以下がすべて:

| モジュール | 対応 | 備考 |
|---|---|---|
| dsu | 1:1 | `size` → `group_size` の改名のみ |
| segtree | 1:1 + 表層 | `SegTree(op, e, v)` が C++ 対応形。`*`/`one` デフォルトと Base 統合(`st[i]`、`prod`、`length`)は設計ノート §1・§3 の表層適応 |
| lazysegtree | 1:1 | |
| fenwicktree | 1:1 + 拡張 | デフォルト構成(`FenwickTree(v)` + `add!` + `sum`)が C++ `fenwick_tree<T>` と 1:1。可換モノイド/可換群への一般化(`op, e, invop`・`prefix`・`mult!`・`invop = nothing`)は設計ノート §4 に基づく**唯一の本質的拡張** |
| modint | 一部欠落 | `static_modint` 相当の `ModInt{M}` のみ。**`dynamic_modint` は未移植**(下記) |
| math | 1:1 | `pow_mod` / `inv_mod` は Base の `powermod` / `invmod` に委譲 |
| string | 1:1 | 位置は 1-indexed(C++ の各要素 +1、突き合わせで検証済み) |
| convolution | 1:1 | `convolution<mod>(a, b)` → `convolution(m, a, b)` |
| scc / twosat | 1:1 | |
| maxflow / mincostflow | 1:1 | |

境界探索(`max_right` / `min_left`)の true 側ラベルと閉区間 API は「同じ境界への
別ラベル」であって意味論の拡張ではない(設計ノート §2・§5。対応関係は `verify/` の
C++ 突き合わせで実測検証済み)。

### dynamic_modint(既知のギャップ)

テストケースを読んでから法が決まる問題(法が入力で与えられる等)のための型。
移植する場合は C++ 版 `dynamic_modint` と同様、**法を型パラメータに入れない**
(実行時の値 + Barrett 逆数をグローバル状態として保持する)設計にすること。
`ModInt{m}` に実行時の `m` を入れる代替も動作はするが、法ごとにメソッドの
再特殊化(JIT)が走り、pkgimage 焼き込みとも相性が悪いため、汎用解にはならない。

## ライセンス

[CC0 1.0](LICENSE)(本家 ACL と同じ)。ライセンス上は、利用・改変・再配布に条件はなく、出典表記も不要。

ただし本リポジトリのコードは生成 AI の支援を受けて作成しているため、**AtCoder のコンテストで使う場合は**、
[生成 AI 利用ルール](https://info.atcoder.jp/entry/llm-rules-ja)により提出コードに本リポジトリへのリンクが必要になる。
`src/` の各ファイル 1 行目のリンク行を残して貼れば、この要件を満たせる。
