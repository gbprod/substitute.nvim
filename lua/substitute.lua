local utils = require("substitute.utils")
local config = require("substitute.config")

local substitute = {}

substitute.state = {
  register = nil,
}

function substitute.setup(options)
  substitute.config = config.setup(options)

  vim.highlight.link("SubstituteRange", "Search")
  vim.highlight.link("SubstituteExchange", "Search")
end

function substitute.operator(options)
  options = options or {}
  substitute.state.register = vim.v.register
  substitute.state.count = options.count or (vim.v.count > 0 and vim.v.count or 1)
  vim.o.operatorfunc = "v:lua.require'substitute'.operator_callback"
  vim.api.nvim_feedkeys("g@" .. (options.motion or ""), "i", false)
end

local function do_substitution(regions, register, count, vmode)
  local replacement = vim.fn.getreg(register)

  if config.options.yank_substitued_text then
    vim.fn.setreg(
      utils.get_default_register(),
      table.concat(utils.get_text(regions), "\n"),
      utils.get_register_type(vmode)
    )
  end

  local text = vim.split(replacement:rep(count):gsub("\n$", ""), "\n")
  for _, region in ipairs(regions) do
    vim.api.nvim_buf_set_text(0, region.start_row - 1, region.start_col, region.end_row - 1, region.end_col + 1, text)
  end

  if config.options.on_substitute ~= nil then
    config.options.on_substitute({
      register = register,
    })
  end
end

function substitute.operator_callback(vmode)
  local regions = utils.get_regions(vmode)
  do_substitution(regions, substitute.state.register, substitute.state.count, vmode)
end

function substitute.line()
  local count = vim.v.count > 0 and vim.v.count or ""
  substitute.operator({
    motion = count .. "_",
    count = 1,
  })
end

function substitute.eol()
  substitute.operator({ motion = "$" })
end

function substitute.visual()
  substitute.state.register = vim.v.register
  substitute.state.count = vim.v.count > 0 and vim.v.count or 1
  vim.cmd([[execute "normal! \<esc>"]])
  substitute.operator_callback(vim.fn.visualmode())
end

return substitute
