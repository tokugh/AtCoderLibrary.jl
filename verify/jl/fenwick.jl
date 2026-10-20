using AtCoderLibrary
const toks = split(read(stdin, String))
const pos = Ref(0)
nxti() = (pos[] += 1; parse(Int, toks[pos[]]))

const out = IOBuffer()
for _ in 1:nxti()
    n = nxti(); q = nxti()
    ft = FenwickTree{Int}(n)
    for _ in 1:q
        c = nxti()
        if c == 0
            p = nxti(); x = nxti()
            add!(ft, p + 1, x)
        else
            l = nxti(); r = nxti()
            println(out, sum(ft, (l+1):r))   # 0-indexed 半開 [l, r) → 1-indexed 閉 [l+1, r]
        end
    end
end
print(String(take!(out)))
