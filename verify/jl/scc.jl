using AtCoderLibrary
const toks = split(read(stdin, String))
const pos = Ref(0)
nxti() = (pos[] += 1; parse(Int, toks[pos[]]))

const out = IOBuffer()
for _ in 1:nxti()
    n = nxti(); m = nxti()
    g = SCCGraph(n)
    for _ in 1:m
        u = nxti(); v = nxti()
        add_edge!(g, u + 1, v + 1)
    end
    cs = scc(g)
    println(out, length(cs))
    for c in cs
        println(out, join(vcat(length(c), c .- 1), ' '))
    end
end
print(String(take!(out)))
