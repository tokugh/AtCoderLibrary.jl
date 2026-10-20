using AtCoderLibrary
const toks = split(read(stdin, String))
const pos = Ref(0)
nxti() = (pos[] += 1; parse(Int, toks[pos[]]))

const out = IOBuffer()
for _ in 1:nxti()
    mode = nxti(); n = nxti(); m = nxti()
    a = [nxti() for _ in 1:n]
    b = [nxti() for _ in 1:m]
    c = mode == 0 ? convolution(998244353, a, b) : convolution_ll(a, b)
    println(out, join(c, ' '))
end
print(String(take!(out)))
