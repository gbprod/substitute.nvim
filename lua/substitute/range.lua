local utils = require("substitute.utils")
local config = require("substitute.config")

local range = {}

range.state = {
  subject = nil,
  match = nil,
  overrides = {},
}

function range.operator(options)
  range.state.overrides = config.get_range(options or {})
  vim.o.operatorfunc = "v:lua.require'substitute.range'.operator_callback"
  vim.api.nvim_feedkeys(string.format("g@%s", range.state.overrides.motion1 or ""), "i", false)
end

function range.visual(options)
  options = config.get_range(options or {})
  options.motion1 = "`>"
  range.operator(options)
end

function range.word(options)
  options = config.get_range(options or {})
  options.motion1 = "iw"
  options.complete_word = true
  range.operator(options)
end

local function create_match()
  range.state.match = vim.fn.matchadd("SubstituteRange", vim.fn.escape(range.state.subject, "\\"), 2)

  vim.cmd([[
    augroup SubstituteClearMatch
      autocmd!
      autocmd InsertEnter,WinLeave,BufLeave * lua require('substitute.range').clear_match()
      autocmd CursorMoved * lua require('substitute.range').clear_match()
    augroup END
  ]])
end

function range.clear_match()
  if nil ~= range.state.match then
    vim.fn.matchdelete(range.state.match)
    range.state.match = nil
  end

  vim.cmd([[
    augroup SubstituteClearMatch
      autocmd!
    augroup END
  ]])
end

function range.operator_callback(vmode)
  local regions = utils.get_regions(vmode)
  if vim.tbl_count(regions) ~= 1 or regions[1].start_row ~= regions[1].end_row then
    vim.notify("Multiline is not supported by SubstituteRange", vim.log.levels.INFO)
    return
  end

  local c = config.get_range(range.state.overrides)

  local line = vim.api.nvim_buf_get_lines(0, regions[1].start_row - 1, regions[1].end_row, true)
  range.state.subject = string.sub(line[1], regions[1].start_col + 1, regions[1].end_col + 1)

  create_match()

  vim.o.operatorfunc = "v:lua.require'substitute.range'.selection_operator_callback"
  vim.api.nvim_feedkeys(string.format("g@%s", c.motion2 or ""), "i", false)
end

local function create_replace_command()
  local c = config.get_range(range.state.overrides)
  local escaped_subject = vim.fn.escape(range.state.subject, "/\\.$[]")
  local escaped_replacement = c.prompt_current_text and vim.fn.escape(range.state.subject, "/\\") or ""

  return string.format(
    vim.api.nvim_replace_termcodes(":'[,']%s/%s/%s/g%s<Left><Left>%s", true, false, true),
    c.prefix,
    c.complete_word and string.format("\\<%s\\>", escaped_subject) or escaped_subject,
    escaped_replacement,
    c.confirm and "c" or "",
    c.confirm and vim.api.nvim_replace_termcodes("<left>", true, false, true) or ""
  )
end

function range.selection_operator_callback()
  range.clear_match()

  vim.api.nvim_feedkeys(create_replace_command(), "tn", true)
end

return range
