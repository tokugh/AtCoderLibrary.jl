using AtCoderLibrary
const toks = split(read(stdin, String))
const pos = Ref(0)
nxti() = (pos[] += 1; parse(Int, toks[pos[]]))

const out = IOBuffer()
for _ in 1:nxti()
    type = nxti()
    if type == 0
        n = nxti(); m = nxti(); a = nxti(); b = nxti()
        println(out, floor_sum(n, m, a, b))
    else
        k = nxti()
        r = [nxti() for _ in 1:k]
        m = [nxti() for _ in 1:k]
        y, z = crt(r, m)
        println(out, y, " ", z)
    end
end
print(String(take!(out)))
