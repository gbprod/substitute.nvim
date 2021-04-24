local substitute = require("substitute")
local range = require("substitute.range")

local function execute_keys(feedkeys)
  local keys = vim.api.nvim_replace_termcodes(feedkeys, true, false, true)
  vim.api.nvim_feedkeys(keys, "x", false)
end

describe("Substitute range", function()
  before_each(function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_command("buffer " .. buf)

    vim.api.nvim_set_keymap(
      "n",
      "<leader>s",
      "<cmd>lua require('substitute.range').operator()<cr>g@",
      { noremap = true }
    )

    vim.api.nvim_buf_set_lines(0, 0, -1, true, {
      "Lorem",
      "ipsum",
      "dolor",
      "sit",
      "amet",
    })
  end)

  it("should prepare replace command", function()
    substitute.setup()

    range.operator()
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 1, 4, {})

    range.operator_callback("char")
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 5, 3, {})

    range.selection_operator_callback()
    execute_keys("<cr>")

    assert.are.equal("'[,']s/Lorem//g", vim.fn.getreg(":"))
  end)

  it("should use abolish", function()
    -- from global config
    substitute.setup({
      range = {
        prefix = "S",
      },
    })

    range.operator()
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 1, 4, {})

    range.operator_callback("char")
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 5, 3, {})

    range.selection_operator_callback()
    execute_keys("<cr>")

    assert.are.equal("'[,']S/Lorem//g", vim.fn.getreg(":"))

    -- from override
    substitute.setup()

    range.operator({ prefix = "S" })
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 1, 4, {})

    range.operator_callback("char")
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 5, 3, {})

    range.selection_operator_callback()
    execute_keys("<cr>")

    assert.are.equal("'[,']S/Lorem//g", vim.fn.getreg(":"))
  end)

  it("should prompt current text", function()
    -- from global config
    substitute.setup({
      range = {
        prompt_current_text = true,
      },
    })

    range.operator()
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 1, 4, {})

    range.operator_callback("char")
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 5, 3, {})

    range.selection_operator_callback()
    execute_keys("<cr>")

    assert.are.equal("'[,']s/Lorem/Lorem/g", vim.fn.getreg(":"))

    -- from override
    substitute.setup()

    range.operator({ prompt_current_text = true })
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 1, 4, {})

    range.operator_callback("char")
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 5, 3, {})

    range.selection_operator_callback()
    execute_keys("<cr>")

    assert.are.equal("'[,']s/Lorem/Lorem/g", vim.fn.getreg(":"))
  end)

  it("should ask for confirmation", function()
    -- from global config
    substitute.setup({
      range = {
        confirm = true,
      },
    })

    range.operator()
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 1, 4, {})

    range.operator_callback("char")
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 5, 3, {})

    range.selection_operator_callback()
    execute_keys("<cr>")

    assert.are.equal("'[,']s/Lorem//gc", vim.fn.getreg(":"))

    -- from override
    substitute.setup()

    range.operator({ confirm = true })
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 1, 4, {})

    range.operator_callback("char")
    vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
    vim.api.nvim_buf_set_mark(0, "]", 5, 3, {})

    range.selection_operator_callback()
    execute_keys("<cr>")

    assert.are.equal("'[,']s/Lorem//gc", vim.fn.getreg(":"))
  end)
end)
