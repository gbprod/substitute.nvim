local utils = require("substitute.utils")
local config = require("substitute.config")

local substitute = {}

substitute.state = {
  register = nil,
}

function substitute.setup(options)
  substitute.config = config.setup(options)

  vim.api.nvim_set_hl(0, "SubstituteRange", { link = "Search" })
  vim.api.nvim_set_hl(0, "SubstituteExchange", { link = "Search" })
end

function substitute.operator(options)
  options = options or {}
  substitute.state.register = options.register or vim.v.register
  substitute.state.count = options.count or (vim.v.count > 0 and vim.v.count or 1)
  vim.o.operatorfunc = "v:lua.require'substitute'.operator_callback"
  vim.api.nvim_feedkeys("g@" .. (options.motion or ""), "i", false)
end

function substitute.operator_callback(vmode)
  local marks = utils.get_marks(0, vmode)

  local substitued_text = utils.text(0, marks.start, marks.finish, vmode)

  local regcontents = vim.fn.getreg(substitute.state.register)
  local regtype = vim.fn.getregtype(substitute.state.register)
  local replacement = vim.split(regcontents:rep(substitute.state.count):gsub("\n$", ""), "\n")

  utils.substitute_text(0, marks.start, marks.finish, vmode, replacement, regtype)

  if config.options.yank_substituted_text then
    vim.fn.setreg(utils.get_default_register(), table.concat(substitued_text, "\n"), utils.get_register_type(vmode))
  end

  if config.options.on_substitute ~= nil then
    config.options.on_substitute({
      marks = marks,
      register = substitute.state.register,
      count = substitute.state.count,
      vmode = vmode,
    })
  end
end

function substitute.line(options)
  options = options or {}
  local count = options.count or (vim.v.count > 0 and vim.v.count or "")
  substitute.operator({
    motion = count .. "_",
    count = 1,
    register = options.register or vim.v.register,
  })
end

function substitute.eol(options)
  options = options or {}
  substitute.operator({
    motion = "$",
    register = options.register or vim.v.register,
    count = options.count or (vim.v.count > 0 and vim.v.count or 1),
  })
end

function substitute.visual(options)
  options = options or {}
  substitute.state.register = options.register or vim.v.register
  substitute.state.count = options.count or (vim.v.count > 0 and vim.v.count or 1)
  vim.cmd([[execute "normal! \<esc>"]])
  substitute.operator_callback(vim.fn.visualmode())
end

return substitute
