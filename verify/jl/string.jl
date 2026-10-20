using AtCoderLibrary
const toks = split(read(stdin, String))
const pos = Ref(0)
nxt() = (pos[] += 1; toks[pos[]])
nxti() = parse(Int, nxt())

const out = IOBuffer()
for _ in 1:nxti()
    type = nxti()
    if type == 0
        s = String(nxt())
        sa = suffix_array(s)
        println(out, join(sa .- 1, ' '))          # 1-indexed → 0-indexed
        println(out, join(lcp_array(s, sa), ' '))
        println(out, join(z_algorithm(s), ' '))
    else
        n = nxti()
        v = [nxti() for _ in 1:n]
        sa = suffix_array(v)
        println(out, join(sa .- 1, ' '))
        println(out, join(lcp_array(v, sa), ' '))
        println(out, join(z_algorithm(v), ' '))
    end
end
print(String(take!(out)))
