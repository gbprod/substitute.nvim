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

    vim.api.nvim_buf_set_lines(0, 0, -1, true, { "Lorem", "ipsum", "dolor", "sit", "amet" })
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

  it("should substitute in visual mode", function()
    execute_keys("yw")
    execute_keys("jv$")
    execute_keys("s")

    assert.are.same({ "Lorem", "Lorem", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should be countable in charwise", function()
    execute_keys("yw")
    execute_keys("j")
    execute_keys("3sw")

    assert.are.same({ "Lorem", "LoremLoremLorem", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should be countable in linewise", function()
    execute_keys("yy")
    execute_keys("j")
    execute_keys("3sw")

    assert.are.same({ "Lorem", "Lorem", "Lorem", "Lorem", "dolor", "sit", "amet" }, get_buf_lines())
  end)

  it("should be countable in visual", function()
    execute_keys("yw")
    execute_keys("jV")
    execute_keys("3s")

    assert.are.same({ "Lorem", "LoremLoremLorem", "dolor", "sit", "amet" }, get_buf_lines())
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

describe("When yank_substitued_text is set", function()
  before_each(function()
    substitute.setup()

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_command("buffer " .. buf)

    vim.api.nvim_buf_set_lines(0, 0, -1, true, { "Lorem", "ipsum", "dolor", "sit", "amet" })
  end)

  it("should yank in default register", function()
    substitute.setup({ yank_substitued_text = true })

    execute_keys("yw")
    execute_keys("j")
    execute_keys("sw")

    assert.are.same("ipsum", vim.fn.getreg())
    assert.are.same("v", vim.fn.getregtype())
  end)

  it("should yank in default register in visual mode", function()
    substitute.setup({ yank_substitued_text = true })

    execute_keys("ywj")
    execute_keys("vjj")
    execute_keys("s")

    assert.are.same("ipsum\ndolor\ns", vim.fn.getreg())
    assert.are.same("v", vim.fn.getregtype())
  end)

  it("should yank in default register in ctrl-v mode", function()
    substitute.setup({ yank_substitued_text = true })

    execute_keys("ywj")
    execute_keys("<c-v>jjl")
    execute_keys("s")

    assert.are.same("ip\ndo\nsi", vim.fn.getreg())
    assert.are.same(vim.api.nvim_replace_termcodes("<c-v>2", true, false, true), vim.fn.getregtype())
  end)
end)
