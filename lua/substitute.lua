local utils = require("substitute.utils")
local config = require("substitute.config")

local substitute = {}

substitute.state = {
  register = nil,
  count = nil,
  curpos = nil,
}

function substitute.setup(options)
  config.setup(options)

  if config.options.highlight_substituted_text.enabled then
    substitute.hl_substitute = vim.api.nvim_create_namespace("yanky.substitute")
    substitute.timer = vim.loop.new_timer()
  end

  vim.api.nvim_set_hl(0, "SubstituteSubstituted", { link = "Search", default = true })
  vim.api.nvim_set_hl(0, "SubstituteRange", { link = "Search", default = true })
  vim.api.nvim_set_hl(0, "SubstituteExchange", { link = "Search", default = true })
end

function substitute.operator(options)
  if not config.check_setup() then
    return
  end
  options = options or {}
  substitute.state.register = options.register or vim.v.register
  substitute.state.count = options.count or (vim.v.count > 0 and vim.v.count or 1)
  substitute.state.modifiers = options.modifiers or nil
  if config.options.preserve_cursor_position then
    substitute.state.curpos = vim.api.nvim_win_get_cursor(0)
  end
  vim.o.operatorfunc = "v:lua.require'substitute'.operator_callback"
  vim.api.nvim_feedkeys("g@" .. (options.motion or ""), "mi", false)
end

function substitute.operator_callback(vmode)
  local marks = utils.get_marks(0, vmode)
  substitute.state.vmode = vmode
  substitute.state.marks = marks

  local substitued_text = utils.text(0, marks.start, marks.finish, vmode)

  local doSubstitution = function(state, _)
    local regcontents = vim.fn.getreg(state.register)
    local regtype = vim.fn.getregtype(state.register)
    local replacement = vim.split(regcontents:rep(substitute.state.count):gsub("\n$", ""), "\n")

    local subs_marks = utils.substitute_text(0, marks.start, marks.finish, vmode, replacement, regtype)

    vim.api.nvim_buf_set_mark(0, "[", subs_marks[1].start.row, subs_marks[1].start.col, {})
    vim.api.nvim_buf_set_mark(0, "]", subs_marks[#subs_marks].finish.row, subs_marks[#subs_marks].finish.col - 1, {})

    if config.options.highlight_substituted_text.enabled then
      substitute.highlight_substituted_text(subs_marks)
    end
  end

  local modifier = config.get_modifiers(substitute.state) or doSubstitution

  modifier(substitute.state, doSubstitution)

  if config.options.yank_substituted_text then
    vim.fn.setreg(utils.get_default_register(), table.concat(substitued_text, "\n"), utils.get_register_type(vmode))
  end

  if nil ~= substitute.state.curpos and config.options.preserve_cursor_position then
    vim.api.nvim_win_set_cursor(0, substitute.state.curpos)
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
    modifiers = options.modifiers or nil,
  })
end

function substitute.eol(options)
  options = options or {}
  substitute.operator({
    motion = "$",
    register = options.register or vim.v.register,
    count = options.count or (vim.v.count > 0 and vim.v.count or 1),
    modifiers = options.modifiers or nil,
  })
end

function substitute.visual(options)
  if not config.check_setup() then
    return
  end
  options = options or {}
  substitute.state.register = options.register or vim.v.register
  substitute.state.count = options.count or (vim.v.count > 0 and vim.v.count or 1)
  substitute.state.modifiers = options.modifiers or nil

  vim.o.operatorfunc = "v:lua.require'substitute'.operator_callback"
  vim.api.nvim_feedkeys("g@`<", "ni", false)
end

function substitute.highlight_substituted_text(marks)
  substitute.timer:stop()
  vim.api.nvim_buf_clear_namespace(0, substitute.hl_substitute, 0, -1)

  for _, mark in pairs(marks) do
    vim.highlight.range(
      0,
      substitute.hl_substitute,
      "SubstituteSubstituted",
      { mark.start.row - 1, mark.start.col },
      { mark.finish.row - 1, mark.finish.col },
      { inclusive = false }
    )
  end

  substitute.timer:start(
    config.options.highlight_substituted_text.timer,
    0,
    vim.schedule_wrap(function()
      vim.api.nvim_buf_clear_namespace(0, substitute.hl_substitute, 0, -1)
    end)
  )
end

return substitute
