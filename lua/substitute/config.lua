local config = {}

config.options = {}

function config.setup(options)
  local default_values = {
    on_substitute = nil,
    yank_substituted_text = false,
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
    },
    exchange = {
      motion = nil,
      use_esc_to_cancel = true,
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

return config
