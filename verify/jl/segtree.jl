using AtCoderLibrary
const toks = split(read(stdin, String))
const pos = Ref(0)
nxti() = (pos[] += 1; parse(Int, toks[pos[]]))

function run_case(out, st, n, q)
    for _ in 1:q
        c = nxti()
        if c == 0
            p = nxti(); x = nxti()
            st[p+1] = x
        elseif c == 1
            l = nxti(); r = nxti()
            println(out, prod(st, (l+1):r))
        elseif c == 2
            println(out, prod(st))
        elseif c == 3
            l = nxti(); k = nxti()
            println(out, max_right(st, l + 1, s -> s < k))       # C++ と同じ数値になる
        else
            r = nxti(); k = nxti()
            println(out, min_left(st, r, s -> s < k) - 1)        # Julia = C++ + 1
        end
    end
end

const out = IOBuffer()
for _ in 1:nxti()
    mono = nxti(); n = nxti(); q = nxti()
    if mono == 0
        run_case(out, SegTree(max, 0, zeros(Int, n)), n, q)
    else
        run_case(out, SegTree(+, 0, zeros(Int, n)), n, q)
    end
end
print(String(take!(out)))
