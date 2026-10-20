using AtCoderLibrary
const toks = split(read(stdin, String))
const pos = Ref(0)
nxti() = (pos[] += 1; parse(Int, toks[pos[]]))

const out = IOBuffer()
for _ in 1:nxti()
    n = nxti(); q = nxti()
    d = DSU(n)
    for _ in 1:q
        c = nxti()
        if c == 0
            u = nxti(); v = nxti()
            println(out, merge!(d, u + 1, v + 1) - 1)   # 代表も 0-indexed に戻して比較
        elseif c == 1
            u = nxti(); v = nxti()
            println(out, same(d, u + 1, v + 1) ? 1 : 0)
        else
            u = nxti()
            println(out, group_size(d, u + 1))
        end
    end
end
print(String(take!(out)))
