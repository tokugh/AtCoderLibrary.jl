using AtCoderLibrary
const toks = split(read(stdin, String))
const pos = Ref(0)
nxti() = (pos[] += 1; parse(Int, toks[pos[]]))

const out = IOBuffer()
for _ in 1:nxti()
    n = nxti(); m = nxti()
    g = MCFGraph{Int,Int}(n)
    for _ in 1:m
        u = nxti(); v = nxti(); c = nxti(); w = nxti()
        add_edge!(g, u + 1, v + 1, c, w)
    end
    sl = slope!(g, 1, n)
    println(out, length(sl))
    for (f, c) in sl
        println(out, f, " ", c)
    end
end
print(String(take!(out)))
