local config = {}

config.options = {}

local function with_defaults(options)
  return {
    on_substitute = options.on_substitute or nil,
    yank_substituted_text = options.yank_substituted_text or false,
    range = {
      prefix = options.range and options.range.prefix or "s",
      prompt_current_text = options.range and options.range.prompt_current_text or false,
      confirm = options.range and options.range.confirm or false,
      complete_word = options.range and options.range.complete_word or false,
      motion1 = options.range and options.range.motion1 or false,
      motion2 = options.range and options.range.motion2 or false,
    },
    exchange = {
      motion = nil,
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
    complete_word = overrides.complete_word or config.options.range.complete_word,
    motion1 = overrides.motion1 or config.options.range.motion1,
    motion2 = overrides.motion2 or config.options.range.motion2,
  }
end

function config.get_exchange(overrides)
  return {
    motion = overrides.motion or config.options.exchange.motion,
  }
end

return config
