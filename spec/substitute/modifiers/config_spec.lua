local substitute = require("substitute")

local function execute_keys(feedkeys)
  local keys = vim.api.nvim_replace_termcodes(feedkeys, true, false, true)
  vim.api.nvim_feedkeys(keys, "x", false)
end

local function get_buf_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, true)
end

local buf
describe("Substitute modifiers", function()
  before_each(function()
    substitute.setup()

    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_command("buffer " .. buf)
  end)

  it("should be taken from a function", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "Lorem", "ipsum", "dolor", "sit", "amet" })

    vim.keymap.set({ "n", "x" }, "]s", function()
      require("substitute").operator({
        modifiers = function(_)
          return { "linewise" }
        end,
      })
    end, { noremap = true })

    execute_keys("lly2l")
    execute_keys("j")
    execute_keys("]s2l")

    assert.are.same({ "Lorem", "ip", "re", "m", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("could be conditionnal", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "    Lorem    ", "ipsum", "dolor", "sit", "amet" })

    vim.keymap.set({ "n", "x" }, "]s", function()
      require("substitute").operator({
        modifiers = function(state)
          return state.vmode == "char" and { "trim" } or { "linewise" }
        end,
      })
    end, { noremap = true })

    execute_keys("yy")
    execute_keys("jll")
    execute_keys("]s2l")

    execute_keys("jV")
    execute_keys("]s")

    assert.are.same({ "    Lorem    ", "ipLoremm", "    Lorem    ", "sit", "amet" }, get_buf_lines())
  end)
end)
