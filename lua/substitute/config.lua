local config = {}

config.options = {}

function config.setup(options)
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
      motion1 = false,
      motion2 = false,
      group_substituted_text = false,
      suffix = "",
      auto_apply = false,
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

return config
