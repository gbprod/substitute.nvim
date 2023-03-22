local modifiers = {}

function modifiers.linewise(next)
  return function(state, callback)
    local body = vim.fn.getreg(state.register)
    local type = vim.fn.getregtype(state.register)

    if state.vmode ~= "line" then
      -- we add a newline at the end nly if we don't replace to the end of a
      -- line and if we don't replace to line mode
      local should_wrap = type ~= "V" and state.marks.finish.col + 1 < vim.fn.getline(state.marks.finish.row):len()
      vim.fn.setreg(state.register, string.format("\n%s\n%s", body, should_wrap and "\n" or ""), type)
    end

    if nil == next then
      callback(state)
    else
      next(state, callback)
    end

    vim.fn.setreg(state.register, body, type)
  end
end

function modifiers.trim(next)
  return function(state, callback)
    local body = vim.fn.getreg(state.register)

    local reformated_body = body:gsub("^%s*", ""):gsub("%s*$", "")
    vim.fn.setreg(state.register, reformated_body, vim.fn.getregtype(state.register))

    if nil == next then
      callback(state)
    else
      next(state, callback)
    end

    vim.fn.setreg(state.register, body, vim.fn.getregtype(state.register))
  end
end

function modifiers.join(next)
  return function(state, callback)
    local body = vim.fn.getreg(state.register)

    local reformated_body = body:gsub("%s*\r?\n%s*", " ")
    vim.fn.setreg(state.register, reformated_body, vim.fn.getregtype(state.register))

    if nil == next then
      callback(state)
    else
      next(state, callback)
    end

    vim.fn.setreg(state.register, body, vim.fn.getregtype(state.register))
  end
end

function modifiers.reindent(next)
  return function(state, callback)
    if nil == next then
      callback(state)
    else
      next(state, callback)
    end

    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("silent '[,']normal! ==")
    vim.api.nvim_win_set_cursor(0, cursor_pos)
  end
end

function modifiers.build(chain)
  if nil == chain then
    return nil
  end

  local modifier = nil
  for index = #chain, 1, -1 do
    modifier = modifiers[chain[index]](modifier)
  end

  return modifier
end

return modifiers
