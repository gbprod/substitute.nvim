local config = {}

config.options = {}

local function with_defaults(options)
  return {
    on_substitute = options.on_substitute or nil,
    yank_substitued_text = options.yank_substitued_text or false,
    range = {
      prefix = options.range and options.range.prefix or "s",
      prompt_current_text = options.range and options.range.prompt_current_text or false,
      confirm = options.range and options.range.confirm or false,
    },
  }
end

function config.setup(options)
  config.options = with_defaults(options or {})
end

function config.get_range(overrides)
  return {
    prefix = overrides.prefix or config.options.range.prefix,
    prompt_current_text = overrides.prompt_current_text or config.options.range.prompt_current_text,
    confirm = overrides.confirm or config.options.range.confirm,
  }
end

return config
