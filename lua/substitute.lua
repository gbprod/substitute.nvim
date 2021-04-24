local utils = require("substitute.utils")
local config = require("substitute.config")

local substitute = {}

substitute.state = {
  register = nil,
}

function substitute.setup(options)
  substitute.config = config.setup(options)
end

function substitute.operator()
  substitute.state.register = vim.v.register
  vim.o.operatorfunc = "v:lua.require'substitute'.operator_callback"
end

local function do_substitution(start_row, start_col, end_row, end_col, register)
  local replacement = vim.fn.getreg(register)

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, vim.split(vim.trim(replacement), "\n"))

  if config.options.on_substitute ~= nil then
    config.options.on_substitute({
      register = register,
    })
  end
end

function substitute.operator_callback(vmode)
  local region = utils.get_region(vmode)
  do_substitution(
    region.start_row - 1,
    region.start_col,
    region.end_row - 1,
    region.end_col + 1,
    substitute.state.register
  )
end

function substitute.line()
  local count = vim.v.count == 0 and 1 or vim.v.count

  local start_line = vim.fn.line(".")
  local end_line = math.min(start_line + count - 1, vim.fn.line("$"))

  do_substitution(start_line - 1, 0, end_line - 1, vim.fn.getline(end_line):len(), vim.v.register)

  if vim.g.loaded_repeat then
    vim.api.nvim_call_function(
      "repeat#set",
      { vim.api.nvim_replace_termcodes("<cmd>lua require('substitute').line()<cr>", true, false, true) }
    )
  end
end

function substitute.eol()
  local position = vim.fn.getcurpos()
  local line = position[2]
  local col = position[3]

  do_substitution(line - 1, col - 1, line - 1, vim.fn.getline("."):len(), vim.v.register)

  if vim.g.loaded_repeat then
    vim.api.nvim_call_function(
      "repeat#set",
      { vim.api.nvim_replace_termcodes("<cmd>lua require('substitute').eol()<cr>", true, false, true) }
    )
  end
end

return substitute
