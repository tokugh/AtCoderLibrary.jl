# ==== 入力(TokenIO ワンライナー版・インタラクティブ問題用。読む前に自動 flush、行単位遅延読み)====
const _IN = Ref(""); const _POS = Ref(1)
input!() = nothing
function _more!(); flush(stdout); eof(stdin) && return false; _IN[] = readline(stdin); _POS[] = 1; return true; end
@inline function _skiptok!(); s = _IN[]; n = ncodeunits(s); p = _POS[]; while true; @inbounds while p <= n && codeunit(s, p) <= 0x20; p += 1; end; if p <= n; _POS[] = p; return true; end; _more!() || (_POS[] = p; return false); s = _IN[]; n = ncodeunits(s); p = _POS[]; end; end
function nextI(); _skiptok!() || return 0; s = _IN[]; n = ncodeunits(s); p = _POS[]; neg = false; @inbounds if codeunit(s, p) == 0x2d; neg = true; p += 1; end; x = 0; @inbounds while p <= n; c = codeunit(s, p); (0x30 <= c <= 0x39) || break; x = 10x + Int(c - 0x30); p += 1; end; _POS[] = p; return neg ? -x : x; end
function nextS(); _skiptok!() || return SubString(_IN[], 1, 0); s = _IN[]; n = ncodeunits(s); p = _POS[]; q = p; @inbounds while q <= n && codeunit(s, q) > 0x20; q += 1; end; _POS[] = q; return SubString(s, p, thisind(s, q - 1)); end
nextF() = parse(Float64, nextS())
function nextC(); _skiptok!() || return '\0'; s = _IN[]; p = _POS[]; c = s[p]; _POS[] = nextind(s, p); return c; end
