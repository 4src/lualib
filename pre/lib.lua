local lib={}

local b4={}; for k,_ in pairs(_ENV) do b4[k] = k end

function lib.rogues()
  for k,_ in pairs(_ENV) do if not b4[k] then
    io.stderr:write("-- warning: rogue local [",k,"]\n") end end end

function lib.new(kl, inst)
  kl.__index = kl; kl.__tostring = lib.o; return setmetatable(inst,kl) end

function lib.copy(t,u)
  if type(t) ~= "table" then return t end
  u={}; for k,v in pairs(t) do u[lib.copy(k)] = lib.copy(v) end 
  return setmetatable(u, getmetatable(t)) end

lib.Seed = 937162211
-- Returns random integers `nlo` to `nhi`.
function lib.rint(nlo,nhi)
  return math.floor(0.5 + lib.rand(nlo,nhi))  end
-- Returns random floats `nlo` to `nhi` (defaults 0 to 1)
function lib.rand(nlo,nhi)
  nlo,nhi=nlo or 0, nhi or 1
  lib.Seed = (16807 * lib.Seed) % 2147483647
  return nlo + (nhi-nlo) * lib.Seed / 2147483647 end

lib.fmt = string.format

-- Returns `x` after pushing onto `t`
function lib.push(t,x) t[#t+1]=x; return x end

function lib.kap(t,fun,     u)
  u={}; for k,v in pairs(t or {}) do v,k=fun(k,v); u[k or (1+#u)]=v; end; return u end

-- Returns a copy of `t` with all items filtered via `fun`.
function lib.map(t, fun) return lib.kap(t, function(_,x) return fun(x) end) end

-- Sorts `t` using `fun`, returns `t`.
function lib.sorted(t,fun)
  table.sort(t,fun)
  return t end

function lib.o(t,     fun)
  if type(t) == "number" then return lib.fmt("%g",t) end
  if type(t) ~= "table"  then return tostring(t) end
  fun = function(k,v) if k ~="^_" then return lib.fmt(":%s %s",k,lib.o(v)) end end
  t = #t>0 and lib.map(t,lib.o) or lib.sorted(lib.kap(t,fun))
  return "{"..table.concat(t," ").."}" end

-- Print `t` (recursively) then return it.
function lib.oo(t) print(lib.o(t)); return t end

-- Convert `s` into an integer, a float, a bool, or a string (as appropriate). Return the result.
function lib.coerce(s,    fun)
  function fun(s) return s=="true" and true or (s ~= "false" and s) or false end
  return math.tointeger(s) or tonumber(s) or fun(s:match"^%s*(.-)%s*$") end

-- Split a `s`  on commas.
function lib.cells(s,    t)
  t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t] = lib.coerce(s1) end; return t end

-- Run `fun` for all lines in a csv file `s` (where each line is divided on ",").
function lib.csv(sFilename,fun,      src,s)
  src = io.input(sFilename)
  while true do
    s = io.read(); if s then fun(lib.cells(s)) else return io.close(src) end end end

-- Return `t`, updated from the command-line.  For `k,v` in
-- `t`,if the command line mentions key `k` then change `s` to a new
-- value.  If the old value is a boolean, just flip the old.
function lib.cli(t)
  for k,v in pairs(t) do
    v = tostring(v)
    for n,x in ipairs(arg) do
      if x=="-"..(k:sub(1,1)) or x=="--"..k then
        v = v=="false" and "true" or v=="true" and "false" or arg[n+1] end end
    t[k] = lib.coerce(v) end
  return t end

-- Parse `help` text to extract settings.
function lib.settings(s,       t,pat)
  pat = "\n[%s]+[-]%S[%s]+([%S]+)[^\n]+= ([%S]+)"
  t={}; s:gsub(pat, function(k,v) t[k]=lib.coerce(v) end)
  return t,s end

return lib 
