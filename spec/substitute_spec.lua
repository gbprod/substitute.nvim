local substitute = require("substitute")

local function get_buf_lines()
  local result = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
  return result
end

local function execute_keys(feedkeys)
  local keys = vim.api.nvim_replace_termcodes(feedkeys, true, false, true)
  vim.api.nvim_feedkeys(keys, "x", false)
end

describe("Substitute", function()
  before_each(function()
    substitute.setup()

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_command("buffer " .. buf)

    vim.api.nvim_set_keymap("n", "ss", "<cmd>lua require('substitute').line()<cr>", { noremap = true })
    vim.api.nvim_set_keymap("n", "S", "<cmd>lua require('substitute').eol()<cr>", { noremap = true })
    vim.api.nvim_set_keymap("n", "s", "<cmd>lua require('substitute').operator()<cr>", { noremap = true })

    vim.api.nvim_buf_set_lines(0, 0, -1, true, {
      "Lorem",
      "ipsum",
      "dolor",
      "sit",
      "amet",
    })
  end)

  it("should substitute line", function()
    execute_keys("yw")
    execute_keys("j")
    execute_keys("ss")

    assert.are.same({ "Lorem", "Lorem", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should substitute last empty line", function()
    execute_keys("yw")
    execute_keys("Go<esc>")
    execute_keys("ss")

    assert.are.same({ "Lorem", "ipsum", "dolor", "sit", "amet", "Lorem" }, get_buf_lines())
  end)

  it("should substitute line from register", function()
    vim.fn.setreg("a", "substitute", "")
    execute_keys('"ass')

    assert.are.same({ "substitute", "ipsum", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should substitute multiple lines", function()
    execute_keys("yw")
    execute_keys("j")
    execute_keys("3ss")

    assert.are.same({ "Lorem", "Lorem", "amet" }, get_buf_lines())
  end)

  it("should substitute multiple lines to eof", function()
    execute_keys("yw")
    execute_keys("2j")
    execute_keys("5ss")

    assert.are.same({
      "Lorem",
      "ipsum",
      "Lorem",
    }, get_buf_lines())
  end)

  it("should substitute to eof", function()
    execute_keys("yw")
    execute_keys("j3l")
    execute_keys("S")

    assert.are.same({ "Lorem", "ipsLorem", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should substitute to eof from register", function()
    vim.fn.setreg("a", "substitute", "")
    execute_keys("4l")
    execute_keys('"aS')

    assert.are.same({ "Loresubstitute", "ipsum", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should substitute string with new lines", function()
    execute_keys("y3w")
    execute_keys("j")
    execute_keys("ss")

    assert.are.same({ "Lorem", "Lorem", "ipsum", "dolor", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should substitute from operator", function()
    execute_keys("yw")
    execute_keys("j")
    execute_keys("sw")

    assert.are.same({ "Lorem", "Lorem", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should substitute from operator in multiple lines", function()
    execute_keys("yw")
    execute_keys("j")
    execute_keys("s3w")

    assert.are.same({ "Lorem", "Lorem", "amet" }, get_buf_lines())
  end)
end)

describe("On substitute option", function()
  it("should be called", function()
    local called = false
    substitute.setup({
      on_substitute = function(_)
        called = true
      end,
    })

    execute_keys("yw")
    execute_keys("sw")

    assert(called)
  end)
end)
