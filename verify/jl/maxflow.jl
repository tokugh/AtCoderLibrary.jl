using AtCoderLibrary
const toks = split(read(stdin, String))
const pos = Ref(0)
nxti() = (pos[] += 1; parse(Int, toks[pos[]]))

const out = IOBuffer()
for _ in 1:nxti()
    n = nxti(); m = nxti()
    g = MFGraph{Int}(n)
    for _ in 1:m
        u = nxti(); v = nxti(); c = nxti()
        add_edge!(g, u + 1, v + 1, c)
    end
    println(out, flow!(g, 1, n))
    println(out, join(Int.(min_cut(g, 1))))
end
print(String(take!(out)))
