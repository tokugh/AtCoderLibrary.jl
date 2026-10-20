#!/bin/bash
# C++ 版 ACL とのランダム突き合わせ検証(再実行可能)
set -u
cd "$(dirname "$0")"
# C++ 版 ACL の場所。既定は verify/ac-library(シンボリックリンク可)。環境変数 ACL で上書きできる。
ACL="${ACL:-ac-library}"
mkdir -p bin tmp

echo "== compile =="
for f in cpp/*.cpp; do
    name=$(basename "$f" .cpp)
    clang++ -std=c++17 -O2 -I "$ACL" -o "bin/$name" "$f" || exit 1
done

echo "== generate =="
julia --project=.. gen.jl || exit 1

echo "== compare =="
fail=0
for name in fenwick segtree lazyseg conv math string scc maxflow mincostflow dsu; do
    ./bin/$name < "tmp/$name.in" > "tmp/$name.cpp.out"
    julia --project=.. "jl/$name.jl" < "tmp/$name.in" > "tmp/$name.jl.out"
    cases=$(head -1 "tmp/$name.in")
    if diff -q "tmp/$name.cpp.out" "tmp/$name.jl.out" > /dev/null; then
        echo "PASS $name ($cases cases)"
    else
        echo "FAIL $name ($cases cases) — diff tmp/$name.cpp.out tmp/$name.jl.out"
        fail=1
    fi
done
exit $fail
