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
  vim.api.nvim_feedkeys("g@", "i", false)
end

local function do_substitution(start_row, start_col, end_row, end_col, register)
  local replacement = vim.fn.getreg(register)

  if config.options.yank_substitued_text then
    vim.fn.setreg(
      utils.get_default_register(),
      table.concat(utils.nvim_buf_get_text(start_row, start_col, end_row, end_col), "\n")
    )
  end

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, vim.split(replacement:gsub("\n$", ""), "\n"))

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
  substitute.state.register = vim.v.register
  vim.o.operatorfunc = "v:lua.require'substitute'.operator_callback"
  local keys = vim.api.nvim_replace_termcodes(
    string.format("g@:normal! 0v%s$<cr>", vim.v.count > 0 and vim.v.count - 1 .. "j" or ""),
    true,
    false,
    true
  )
  vim.api.nvim_feedkeys(keys, "i", false)
end

function substitute.eol()
  substitute.state.register = vim.v.register
  vim.o.operatorfunc = "v:lua.require'substitute'.operator_callback"
  vim.api.nvim_feedkeys("g@$", "i", false)
end

function substitute.visual()
  substitute.state.register = vim.v.register
  vim.o.operatorfunc = "v:lua.require'substitute'.operator_callback"
  vim.api.nvim_feedkeys("g@`>", "i", false)
end

return substitute
