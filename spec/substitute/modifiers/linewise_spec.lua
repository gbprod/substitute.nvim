local substitute = require("substitute")

local function get_buf_lines()
  local result = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
  return result
end

local function execute_keys(feedkeys)
  local keys = vim.api.nvim_replace_termcodes(feedkeys, true, false, true)
  vim.api.nvim_feedkeys(keys, "x", false)
end

describe("Substitute linewise", function()
  before_each(function()
    substitute.setup()

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_command("buffer " .. buf)

    vim.keymap.set({ "n", "x" }, "]s", function()
      require("substitute").operator({
        modifiers = { "linewise" },
      })
    end, { noremap = true })

    vim.keymap.set({ "n", "x" }, "]ss", function()
      require("substitute").line({
        modifiers = { "linewise" },
      })
    end, { noremap = true })

    vim.api.nvim_buf_set_lines(0, 0, -1, true, { "Lorem", "ipsum", "dolor", "sit", "amet" })
  end)

  it("should substitute linewise", function()
    execute_keys("y3l")
    execute_keys("jll")
    execute_keys("]s2l")

    assert.are.same({ "Lorem", "ip", "Lor", "m", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should substitute linewise from linewise", function()
    execute_keys("yy")
    execute_keys("jll")
    execute_keys("]s2l")

    assert.are.same({ "Lorem", "ip", "Lorem", "m", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should substitute linewise in visual mode", function()
    execute_keys("y3l")
    execute_keys("jll")
    execute_keys("vl")
    execute_keys("]s")

    assert.are.same({ "Lorem", "ip", "Lor", "m", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should substitute linewise in line mode", function()
    execute_keys("y3l")
    execute_keys("jll")
    execute_keys("]ss")

    assert.are.same({ "Lorem", "Lor", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should substitute linewise at the end of line", function()
    execute_keys("y3l")
    execute_keys("jll")
    execute_keys("]s$")

    assert.are.same({ "Lorem", "ip", "Lor", "dolor", "sit", "amet" }, get_buf_lines())
  end)
end)
