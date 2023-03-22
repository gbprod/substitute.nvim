local substitute = require("substitute")

local function get_buf_lines()
  local result = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
  return result
end

local function execute_keys(feedkeys)
  local keys = vim.api.nvim_replace_termcodes(feedkeys, true, false, true)
  vim.api.nvim_feedkeys(keys, "x", false)
end

local buf = nil
describe("Substitute reindent", function()
  before_each(function()
    substitute.setup()

    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_command("buffer " .. buf)

    vim.keymap.set({ "n", "x" }, "=s", function()
      require("substitute").operator({
        modifiers = { "reindent" },
      })
    end, { noremap = true, buffer = buf })

    vim.keymap.set({ "n", "x" }, "=ss", function()
      require("substitute").line({
        modifiers = { "reindent" },
      })
    end, { noremap = true, buffer = buf })

    vim.api.nvim_set_option_value("shiftwidth", 4, { buf = buf })
  end)

  it("should substitute and reindent line", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "    Lorem", "ipsum", "    dolor", "    sit", "    amet" })

    execute_keys("wy3l")
    execute_keys("j0ll")
    execute_keys("=s2l")

    assert.are.same({ "    Lorem", "    ipLorm", "    dolor", "    sit", "    amet" }, get_buf_lines())
  end)

  it("should substitute and reindent multiple lines", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "    Lorem", "ipsum", "    dolor", "    sit", "    amet" })

    execute_keys("wy3l")
    execute_keys("j0ll")
    execute_keys("=s2w")

    assert.are.same({ "    Lorem", "    ipLor", "    sit", "    amet" }, get_buf_lines())
  end)

  it("should substitute line and reindent line", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "    Lorem", "ipsum", "    dolor", "    sit", "    amet" })

    execute_keys("wy3l")
    execute_keys("j0ll")
    execute_keys("=ss")

    assert.are.same({ "    Lorem", "    Lor", "    dolor", "    sit", "    amet" }, get_buf_lines())
  end)

  it("should substitute lines and reindent lines", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "    Lorem", "ipsum", "    dolor", "    sit", "    amet" })

    execute_keys("wy3l")
    execute_keys("j0ll")
    execute_keys("2=ss")

    assert.are.same({ "    Lorem", "    Lor", "    sit", "    amet" }, get_buf_lines())
  end)
end)

describe("Substitute linewise and reindent", function()
  before_each(function()
    substitute.setup()

    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_command("buffer " .. buf)

    vim.keymap.set({ "n", "x" }, "=s", function()
      require("substitute").operator({
        modifiers = { "linewise", "reindent" },
      })
    end, { noremap = true, buffer = buf })

    vim.keymap.set({ "n", "x" }, "=ss", function()
      require("substitute").line({
        modifiers = { "linewise", "reindent" },
      })
    end, { noremap = true, buffer = buf })

    vim.api.nvim_set_option_value("shiftwidth", 4, { buf = buf })
  end)

  it("should substitute and reindent line", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "    Lorem", "ipsum", "    dolor", "    sit", "    amet" })

    execute_keys("wy3l")
    execute_keys("j0ll")
    execute_keys("=s2l")

    assert.are.same({ "    Lorem", "    ip", "    Lor", "    m", "    dolor", "    sit", "    amet" }, get_buf_lines())
  end)

  it("should substitute and reindent multiple lines", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "    Lorem", "ipsum", "    dolor", "    sit", "    amet" })

    execute_keys("wy3l")
    execute_keys("j0ll")
    execute_keys("=s2w")

    assert.are.same({ "    Lorem", "    ip", "    Lor", "    sit", "    amet" }, get_buf_lines())
  end)

  it("should substitute line and reindent line", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "    Lorem", "ipsum", "    dolor", "    sit", "    amet" })

    execute_keys("wy3l")
    execute_keys("j")
    execute_keys("=ss")

    assert.are.same({ "    Lorem", "    Lor", "    dolor", "    sit", "    amet" }, get_buf_lines())
  end)

  it("should substitute lines and reindent lines", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "    Lorem", "ipsum", "    dolor", "    sit", "    amet" })

    execute_keys("wy3l")
    execute_keys("j0ll")
    execute_keys("2=ss")

    assert.are.same({ "    Lorem", "    Lor", "    sit", "    amet" }, get_buf_lines())
  end)

  it("should reindent until eol", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "    Lorem", "ipsum", "    dolor", "    sit", "    amet" })

    execute_keys("wy3l")
    execute_keys("j0ll")
    execute_keys("=s$")

    assert.are.same({ "    Lorem", "    ip", "    Lor", "    dolor", "    sit", "    amet" }, get_buf_lines())
  end)
end)
