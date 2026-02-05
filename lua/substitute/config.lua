local config = {}

config.options = {}
config.did_setup = false

function config.setup(options)
  config.did_setup = true
  local default_values = {
    on_substitute = nil,
    yank_substituted_text = false,
    preserve_cursor_position = false,
    modifiers = nil,
    highlight_substituted_text = {
      enabled = true,
      timer = 500,
    },
    range = {
      prefix = "s",
      prompt_current_text = false,
      confirm = false,
      complete_word = false,
      subject = nil,
      range = nil,
      group_substituted_text = false,
      suffix = "",
      auto_apply = false,
      cursor_position = "end",
    },
    exchange = {
      motion = nil,
      use_esc_to_cancel = true,
      preserve_cursor_position = false,
    },
  }

  config.options = vim.tbl_deep_extend("force", default_values, options or {})
end

function config.get_range(overrides)
  local default_values = vim.tbl_deep_extend("force", config.options.range, {
    register = vim.v.register,
  })

  return vim.tbl_deep_extend("force", default_values, overrides or {})
end

function config.get_exchange(overrides)
  return {
    motion = overrides.motion or config.options.exchange.motion,
  }
end

function config.get_modifiers(state)
  if type(state.modifiers) == "function" then
    return require("substitute.modifiers").build(state.modifiers(state))
  end

  if type(state.modifiers) == "table" then
    return require("substitute.modifiers").build(state.modifiers)
  end

  return config.options.modifiers
end

function config.check_setup()
  if not config.did_setup then
    vim.notify(
      "[substitute.nvim] setup() must be called before using substitute.nvim. See :h substitute.nvim-configuration",
      vim.log.levels.ERROR
    )
    return false
  end
  return true
end

return config
