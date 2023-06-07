local utils = require("substitute.utils")
local config = require("substitute.config")

local range = {}

range.state = {
  subject = nil,
  match = nil,
  augroup = nil,
  overrides = {},
}

local function get_text_from(text)
  if type(text) == "function" then
    return text()
  elseif type(text) == "string" then
    return text
  elseif type(text) == "table" then
    if text.register then
      return vim.fn.getreg(text.register)
    elseif text.expand then
      return vim.fn.expand(text.expand)
    elseif text.last_search then
      return vim.fn.getreg("/")
    end
  end
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

function range.operator(options)
  range.state.overrides = config.get_range(options or {})
  if not range.state.overrides.motion1 and range.state.overrides.subject then
    local text = get_text_from(range.state.overrides.subject)
    if text then
      range.state.subject = text
      range.operator_callback()
      return
    else
      pcall(function()
        range.state.overrides.motion1 = range.state.overrides.subject.motion
      end)
    end
  end

  range.state.subject = nil
  vim.o.operatorfunc = "v:lua.require'substitute.range'.operator_callback"
  vim.api.nvim_feedkeys(string.format("g@%s", range.state.overrides.motion1 or ""), "mi", false)
end

local function get_selection_text(vmode)
  local marks = utils.get_marks(0, vmode)
  local text = utils.text(0, marks.start, marks.finish, vmode)
  if vim.tbl_count(text) ~= 1 then
    vim.notify("Multiline is not supported by SubstituteRange", vim.log.levels.INFO)
    return
  end

  return table.remove(text)
end

local function get_selection_range(vmode)
  local marks = utils.get_marks(0, vmode)
  return string.format("%d,%d", marks.start.row, marks.finish.row)
end

function range.visual(options)
  vim.cmd([[execute "normal! \<esc>"]])
  range.state.overrides = config.get_range(options or {})
  local vmode = vim.fn.visualmode()
  range.state.subject = nil
  range.operator_callback(vmode)
end

function range.in_selected_range(options)
  options = config.get_range(options or {})
  options.range = range.last_visual_range
  range.operator(options)
end
function range.select_range(options)
  vim.cmd([[execute "normal! \<esc>"]])
  options = config.get_range(options or {})
  range.last_visual_range = get_selection_range(vim.fn.visualmode())

  if options.subject then
    range.in_selected_range(options)
  end
end
function range.visual_range(options)
  if vim.api.nvim_get_mode().mode:lower() ~= "v" then
    range.in_selected_range(options)
  else
    range.select_range(options)
  end
end

function range.word(options)
  options = config.get_range(options or {})
  options.motion1 = "iw"
  options.complete_word = true
  range.operator(options)
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
  local c = config.get_range(range.state.overrides)

  if range.state.subject == nil then
    range.state.subject = get_selection_text(vmode)
    if range.state.subject == nil then
      return
    end
  end

  if not c.motion2 and c.range then
    if type(c.range) == "function" then
      range.state.range = c.range()
    elseif type(c.range) == "string" then
      range.state.range = c.range
    end
    range.selection_operator_callback()
    return
  end

  create_match(c)
  range.state.range = "'[,']"
  vim.o.operatorfunc = "v:lua.require'substitute.range'.selection_operator_callback"
  vim.api.nvim_feedkeys(string.format("g@%s", c.motion2 or ""), "mi", false)
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

  vim.print(range)
  local cmd = string.format(
    -- vim.api.nvim_replace_termcodes(":%s%s/%s/%s/g%s%s%s", true, false, true),
    ":%s%s/%s/%s/g%s%s%s",
    range.state.range,
    c.prefix,
    get_escaped_subject(c),
    get_escaped_replacement(c),
    c.confirm and "c" or "",
    c.suffix,
    string.rep(left, 2 + (c.confirm and c.suffix:len() + 1 or c.suffix:len()), "")
  )
  vim.print(cmd)
  return cmd
end

function range.selection_operator_callback()
  range.clear_match()

  vim.api.nvim_feedkeys(range.create_replace_command(), "ni", true)
end

return range
