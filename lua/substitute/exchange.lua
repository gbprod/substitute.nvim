local utils = require("substitute.utils")
local config = require("substitute.config")

local exchange = {}

local hl_namespace = vim.api.nvim_create_namespace("substitute.exchange")

local prepare_exchange = function(vmode)
  local marks = utils.get_marks(0, vmode)
  local regtype = utils.get_register_type(vmode)

  vim.highlight.range(
    0,
    hl_namespace,
    "SubstituteExchange",
    { marks.start.row - 1, regtype ~= "l" and marks.start.col or 0 },
    { marks.finish.row - 1, regtype ~= "l" and marks.finish.col + 1 or 0 },
    { regtype = ({ char = "v", line = "V" })[vmode], inclusive = false }
  )

  vim.b.exchange_origin = {
    marks = marks,
    regtype = regtype,
  }

  if config.options.exchange.use_esc_to_cancel then
    vim.b.exchange_esc_previous_mapping = vim.fn.maparg("<Esc>", "n", false, true)
    vim.keymap.set("n", "<Esc>", exchange.cancel)
  end

  vim.api.nvim_buf_attach(0, false, {
    on_lines = function()
      exchange.cancel()
      return true
    end,
  })

  if config.options.exchange.preserve_cursor_position and nil ~= vim.b.exchange_curpos then
    vim.api.nvim_win_set_cursor(0, vim.b.exchange_curpos)
    vim.b.exchange_curpos = nil
  end
end

local function do_exchange(vmode)
  local origin = vim.b.exchange_origin
  local regtype = utils.get_register_type(vmode)
  local target = {
    marks = utils.get_marks(0, regtype),
    regtype = regtype,
  }

  local cmp = utils.compare_regions(origin, target)

  if cmp == "=" then
    vim.notify("Overlapping regions, cannot apply exchange.", vim.log.levels.INFO, {})
    return
  end

  if cmp == ">" or cmp == "]" then
    origin, target = target, origin
  end

  local origin_text = utils.text(0, origin.marks.start, origin.marks.finish, origin.regtype)
  local target_text = utils.text(0, target.marks.start, target.marks.finish, target.regtype)

  if cmp == "<" or cmp == ">" then
    utils.substitute_text(0, target.marks.start, target.marks.finish, target.regtype, origin_text, origin.regtype)
  end

  utils.substitute_text(0, origin.marks.start, origin.marks.finish, origin.regtype, target_text, target.regtype)
  if config.options.exchange.preserve_cursor_position and nil ~= vim.b.exchange_curpos then
    vim.api.nvim_win_set_cursor(0, vim.b.exchange_curpos)
    vim.b.exchange_curpos = nil
  end
end

function exchange.operator(options)
  if not config.check_setup() then
    return
  end
  options = config.get_exchange(options or {})
  vim.o.operatorfunc = "v:lua.require'substitute.exchange'.operator_callback"
  if config.options.exchange.preserve_cursor_position then
    vim.b.exchange_curpos = vim.api.nvim_win_get_cursor(0)
  end
  vim.api.nvim_feedkeys(string.format("g@%s", options.motion or ""), "mi", false)
end

function exchange.visual(options)
  options = config.get_exchange(options or {})
  options.motion = "`>"
  exchange.operator(options)
end

function exchange.line(options)
  options = config.get_exchange(options or {})
  options.motion = (vim.v.count > 0 and vim.v.count or "") .. "_"
  exchange.operator(options)
end

function exchange.operator_callback(vmode)
  if utils.is_blockwise(vmode) then
    vim.notify("Exchange doesn't works with blockwise selections (for the moment)", vim.log.levels.INFO, {})
    return
  end

  if vim.b.exchange_origin == nil then
    prepare_exchange(vmode)
  else
    do_exchange(vmode)
  end
end

function exchange.cancel()
  vim.api.nvim_buf_clear_namespace(0, hl_namespace, 0, -1)
  vim.b.exchange_origin = nil

  if config.options.exchange.use_esc_to_cancel and nil ~= vim.b.exchange_esc_previous_mapping then
    if vim.tbl_isempty(vim.b.exchange_esc_previous_mapping) then
      vim.keymap.set("n", "<Esc>", "<Nop>")
    else
      vim.fn.mapset("n", false, vim.b.exchange_esc_previous_mapping)
    end
    vim.b.exchange_esc_previous_mapping = nil
  end
end

return exchange
