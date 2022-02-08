local utils = require("substitute.utils")
local config = require("substitute.config")

local exchange = {}

local hl_namespace = vim.api.nvim_create_namespace("substitute.exchange")

local prepare_exchange = function(vmode)
  local regions = utils.get_regions(vmode)
  utils.highlight_regions(regions, "SubstituteExchange", hl_namespace)

  vim.b.exchange_origin = regions

  vim.api.nvim_buf_attach(0, false, {
    on_lines = function()
      exchange.cancel()
      return true
    end,
  })
end

local function do_exchange(vmode)
  local origin_regions = vim.b.exchange_origin
  local target_regions = utils.get_regions(vmode)

  local cmp = utils.compare_regions(origin_regions, target_regions)

  if cmp == "=" then
    vim.notify("Overlapping regions, cannot apply exchange.", vim.log.levels.INFO, {})
    return
  end

  if cmp == ">" or cmp == "]" then
    origin_regions, target_regions = target_regions, origin_regions
  end

  local origin_text = utils.get_text(origin_regions)
  local target_text = utils.get_text(target_regions)

  if cmp == "<" or cmp == ">" then
    for _, region in ipairs(target_regions) do
      vim.api.nvim_buf_set_text(
        0,
        region.start_row - 1,
        region.start_col,
        region.end_row - 1,
        region.end_col + 1,
        origin_text
      )
    end
  end

  for _, region in ipairs(origin_regions) do
    vim.api.nvim_buf_set_text(
      0,
      region.start_row - 1,
      region.start_col,
      region.end_row - 1,
      region.end_col + 1,
      target_text
    )
  end

  exchange.cancel()
end

function exchange.operator(options)
  options = config.get_exchange(options or {})
  vim.o.operatorfunc = "v:lua.require'substitute.exchange'.operator_callback"
  vim.api.nvim_feedkeys(string.format("g@%s", options.motion or ""), "i", false)
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
  if vmode == vim.api.nvim_replace_termcodes("<c-v>", true, false, true) then
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
end

return exchange
