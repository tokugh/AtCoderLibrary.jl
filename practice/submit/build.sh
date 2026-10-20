#!/bin/bash
# 提出用の自己完結ファイルを生成する。
# 構成: 入力関数(tokenio.jl ワンライナー版)→ ソルバ(solvers/*.jl)→ ライブラリのコピペ(src/*.jl)
set -eu
cd "$(dirname "$0")"
SRC=../../src

build() {
    prob=$1; shift
    {
        cat tokenio.jl
        echo
        cat "solvers/$prob.jl"
        for lib in "$@"; do
            echo
            echo "# ==== ライブラリ: $lib.jl ===="
            cat "$SRC/$lib.jl"
        done
    } > "$prob.jl"
}

build a dsu
build b fenwicktree
build c math
build d maxflow
build e mincostflow
build f modint convolution
build g scc
build h scc twosat
build i string
build j segtree
build k modint lazysegtree
build l lazysegtree

echo "生成完了:"
wc -c [a-l].jl
