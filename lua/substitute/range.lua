local utils = require("substitute.utils")
local config = require("substitute.config")

local range = {}

range.state = {
  subject = nil,
  match = nil,
  augroup = nil,
  overrides = {},
}

function range.operator(options)
  range.state.overrides = config.get_range(options or {})
  vim.o.operatorfunc = "v:lua.require'substitute.range'.operator_callback"
  vim.api.nvim_feedkeys(string.format("g@%s", range.state.overrides.motion1 or ""), "ni", false)
end

function range.visual(options)
  vim.cmd([[execute "normal! \<esc>"]])
  range.state.overrides = config.get_range(options or {})
  range.operator_callback(vim.fn.visualmode())
end

function range.word(options)
  options = config.get_range(options or {})
  options.motion1 = "iw"
  options.complete_word = true
  range.operator(options)
end

local function get_escaped_subject(c)
  local escaped_subject = vim.fn.escape(range.state.subject, "/\\.$[]")
  escaped_subject = c.complete_word and string.format("\\<%s\\>", escaped_subject) or escaped_subject

  return c.group_substituted_text and string.format("\\(%s\\)", escaped_subject) or escaped_subject
end

local function create_match(c)
  range.clear_match()
  range.state.match = vim.fn.matchadd("SubstituteRange", get_escaped_subject(c), 2)

  range.state.augroup = vim.api.nvim_create_augroup("SubstituteClearMatch", { clear = true })
  vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave", "BufLeave", "CursorMoved" }, {
    group = range.state.augroup,
    pattern = "*",
    callback = range.clear_match,
  })
end

function range.clear_match()
  if nil ~= range.state.match then
    vim.fn.matchdelete(range.state.match)
    range.state.match = nil
  end

  if nil ~= range.state.augroup then
    vim.api.nvim_clear_autocmds({ group = range.state.augroup })
  end
end

function range.operator_callback(vmode)
  local marks = utils.get_marks(0, vmode)
  local text = utils.text(0, marks.start, marks.finish, vmode)
  if vim.tbl_count(text) ~= 1 then
    vim.notify("Multiline is not supported by SubstituteRange", vim.log.levels.INFO)
    return
  end

  local c = config.get_range(range.state.overrides)

  range.state.subject = table.remove(text)

  create_match(c)

  vim.o.operatorfunc = "v:lua.require'substitute.range'.selection_operator_callback"
  vim.api.nvim_feedkeys(string.format("g@%s", c.motion2 or ""), "ni", false)
end

local function get_escaped_replacement(c)
  local default_reg = utils.get_default_register()
  if c.register == default_reg and c.prompt_current_text then
    return range.state.subject
  end

  local replacement = c.register ~= default_reg and vim.fn.getreg(c.register) or ""

  return vim.fn.escape(replacement, "/\\"):gsub("\n$", ""):gsub("\n", "\\r") or ""
end

function range.create_replace_command()
  local c = config.get_range(range.state.overrides)

  local left = vim.api.nvim_replace_termcodes("<left>", true, false, true)

  return string.format(
    vim.api.nvim_replace_termcodes(":'[,']%s/%s/%s/g%s%s<Left><Left>%s", true, false, true),
    c.prefix,
    get_escaped_subject(c),
    get_escaped_replacement(c),
    c.confirm and "c" or "",
    c.suffix,
    string.rep(left, c.confirm and c.suffix:len() + 1 or c.suffix:len(), "")
  )
end

function range.selection_operator_callback()
  range.clear_match()

  vim.api.nvim_feedkeys(range.create_replace_command(), "ni", true)
end

return range
