-- The one impure group module: it writes globals rather than returning a
-- highlight table, so highlights.lua does not merge it. load() calls it.
return function(p)
  for i = 0, 15 do
    vim.g["terminal_color_" .. i] = p.ansi[i]
  end
end
