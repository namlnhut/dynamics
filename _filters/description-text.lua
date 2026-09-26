-- Plain-text copy of a description that contains math, for places that cannot render it:
-- the <meta name="description"> tag and social link previews. The listing and the post
-- header keep the real math. "$\lambda = \ln 2$ at $r \to \infty$" becomes "λ = ln 2 at r → ∞".

local SYMBOLS = {
  alpha = "α", beta = "β", gamma = "γ", delta = "δ", epsilon = "ε", varepsilon = "ε",
  zeta = "ζ", eta = "η", theta = "θ", vartheta = "ϑ", kappa = "κ", lambda = "λ", mu = "μ",
  nu = "ν", xi = "ξ", pi = "π", rho = "ρ", sigma = "σ", tau = "τ", phi = "ϕ", varphi = "φ",
  chi = "χ", psi = "ψ", omega = "ω",
  Gamma = "Γ", Delta = "Δ", Theta = "Θ", Lambda = "Λ", Xi = "Ξ", Pi = "Π", Sigma = "Σ",
  Phi = "Φ", Psi = "Ψ", Omega = "Ω",
  R = "ℝ", N = "ℕ", Z = "ℤ", C = "ℂ", Q = "ℚ", flow = "φ",
  to = "→", rightarrow = "→", mapsto = "↦", infty = "∞", partial = "∂", nabla = "∇",
  le = "≤", leq = "≤", ge = "≥", geq = "≥", ne = "≠", neq = "≠", approx = "≈", sim = "∼",
  pm = "±", mp = "∓", times = "×", cdot = "·", circ = "∘", ["in"] = "∈", subset = "⊂",
  ldots = "…", cdots = "⋯", sum = "∑", int = "∫",
}
local SUPER = { ["0"] = "⁰", ["1"] = "¹", ["2"] = "²", ["3"] = "³", ["4"] = "⁴", ["5"] = "⁵",
  ["6"] = "⁶", ["7"] = "⁷", ["8"] = "⁸", ["9"] = "⁹", ["+"] = "⁺", ["-"] = "⁻", ["="] = "⁼",
  ["("] = "⁽", [")"] = "⁾", i = "ⁱ", k = "ᵏ", n = "ⁿ", p = "ᵖ", t = "ᵗ", T = "ᵀ", x = "ˣ" }
local SUB = { ["0"] = "₀", ["1"] = "₁", ["2"] = "₂", ["3"] = "₃", ["4"] = "₄", ["5"] = "₅",
  ["6"] = "₆", ["7"] = "₇", ["8"] = "₈", ["9"] = "₉", ["+"] = "₊", ["-"] = "₋", ["="] = "₌",
  ["("] = "₍", [")"] = "₎", a = "ₐ", e = "ₑ", h = "ₕ", i = "ᵢ", j = "ⱼ", k = "ₖ", l = "ₗ", m = "ₘ",
  n = "ₙ", o = "ₒ", p = "ₚ", r = "ᵣ", s = "ₛ", t = "ₜ", u = "ᵤ", v = "ᵥ", x = "ₓ" }

-- Map each character through `tbl`; fall back to "^x" or "^(x + y)" if any is missing.
local function script(tbl, mark, s)
  local out = {}
  for _, ch in utf8.codes((s:gsub("%s", ""))) do
    local c = utf8.char(ch)
    if not tbl[c] then
      return mark .. (utf8.len(s) == 1 and s or "(" .. s .. ")")
    end
    out[#out + 1] = tbl[c]
  end
  return table.concat(out)
end

local function tex_to_text(s)
  s = s:gsub("\\dot%s*{?(%a)}?", "%1\u{0307}")
  s = s:gsub("\\sqrt%s*{([^}]*)}", "√%1")
  s = s:gsub("\\mathbb%s*{(%a)}", function(x) return SYMBOLS[x] or x end)
  s = s:gsub("\\math%a+%s*{([^}]*)}", "%1")
  s = s:gsub("\\operatorname%s*{([^}]*)}", "%1")
  s = s:gsub("\\(%a+)", function(name) return SYMBOLS[name] or name end)
  s = s:gsub("%^{([^}]*)}", function(x) return script(SUPER, "^", x) end)
  s = s:gsub("%^(%w)", function(x) return script(SUPER, "^", x) end)
  s = s:gsub("_{([^}]*)}", function(x) return script(SUB, "_", x) end)
  s = s:gsub("_(%w)", function(x) return script(SUB, "_", x) end)
  s = s:gsub("\\[,;:! ]", " ")
  s = s:gsub("[{}]", "")
  s = s:gsub("%s+", " ")
  return s
end

function Meta(meta)
  local desc = meta.description
  if desc == nil or pandoc.utils.type(desc) ~= "Inlines" then return nil end

  local has_math = false
  local plain = pandoc.utils.stringify(desc:walk({
    Math = function(m)
      has_math = true
      return pandoc.Str(tex_to_text(m.text))
    end,
  }))
  if not has_math then return nil end

  meta["description-meta"] = plain
  for _, key in ipairs({ "open-graph", "twitter-card" }) do
    local value = meta[key]
    if value == nil or value == true then
      meta[key] = { description = plain }
    elseif pandoc.utils.type(value) == "table" and value.description == nil then
      value.description = plain
    end
  end
  return meta
end
