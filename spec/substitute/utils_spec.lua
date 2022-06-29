local utils = require("substitute.utils")

local function execute_keys(feedkeys)
  local keys = vim.api.nvim_replace_termcodes(feedkeys, true, false, true)
  vim.api.nvim_feedkeys(keys, "x", false)
end

local function create_test_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_command("buffer " .. buf)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, {
    "Lorem ipsum dolor sit amet,",
    "consectetur adipiscing elit.",
    "Nulla malesuada lacus at ornare accumsan.",
  })
end

describe("Get regions in operatorfunc", function()
  before_each(create_test_buffer)

  it("should select word", function()
    local region
    _G.callback = function()
      region = utils.get_regions(vim.fn.visualmode())
    end

    vim.o.operatorfunc = "v:lua.callback"
    execute_keys("g@iw")

    assert.are.same({ { start_row = 1, start_col = 0, end_row = 1, end_col = 4 } }, region)
  end)

  it("should select to end of the line", function()
    local region
    _G.callback = function()
      region = utils.get_regions(vim.fn.visualmode())
    end

    execute_keys("2w")
    vim.o.operatorfunc = "v:lua.callback"
    execute_keys("g@$")

    assert.are.same({ { start_row = 1, start_col = 12, end_row = 1, end_col = 26 } }, region)
  end)

  it("should select many lines", function()
    local region
    _G.callback = function()
      region = utils.get_regions(vim.fn.visualmode())
    end

    execute_keys("2w")
    vim.o.operatorfunc = "v:lua.callback"
    execute_keys("g@5w")

    assert.are.same({ { start_row = 1, start_col = 12, end_row = 2, end_col = 11 } }, region)
  end)

  it("should select to end of file", function()
    local region
    _G.callback = function()
      region = utils.get_regions(vim.fn.visualmode())
    end

    execute_keys("w")
    vim.o.operatorfunc = "v:lua.callback"
    execute_keys("g@G")

    assert.are.same({ { start_row = 1, start_col = 6, end_row = 3, end_col = 6 } }, region)
  end)
end)

describe("Get regions in visual mode", function()
  before_each(create_test_buffer)

  it("should select word", function()
    execute_keys("ve<esc>")
    local region = utils.get_regions(vim.fn.visualmode())

    assert.are.same({ { start_row = 1, start_col = 0, end_row = 1, end_col = 4 } }, region)
  end)

  it("should select to end of the line", function()
    execute_keys("2w")
    execute_keys("v$<esc>")
    local region = utils.get_regions(vim.fn.visualmode())

    assert.are.same({ { start_row = 1, start_col = 12, end_row = 1, end_col = 26 } }, region)
  end)

  it("should select many lines", function()
    execute_keys("2w")
    execute_keys("v5w<esc>")
    local region = utils.get_regions(vim.fn.visualmode())

    assert.are.same({ { start_row = 1, start_col = 12, end_row = 2, end_col = 12 } }, region)
  end)

  it("should select to end of file", function()
    execute_keys("w")
    execute_keys("vG<esc>")
    local region = utils.get_regions(vim.fn.visualmode())

    assert.are.same({ { start_row = 1, start_col = 6, end_row = 3, end_col = 6 } }, region)
  end)
end)

describe("Get regions in VISUAL mode", function()
  before_each(create_test_buffer)

  it("should select line", function()
    execute_keys("w")
    execute_keys("V<esc>")
    local region = utils.get_regions(vim.fn.visualmode())

    assert.are.same({ { start_row = 1, start_col = 0, end_row = 1, end_col = 26 } }, region)
  end)

  it("should select multiple lines", function()
    execute_keys("wj")
    execute_keys("Vj<esc>")
    local region = utils.get_regions(vim.fn.visualmode())

    assert.are.same({ { start_row = 2, start_col = 0, end_row = 3, end_col = 40 } }, region)
  end)
end)

describe("Get regions in CTRL-V mode", function()
  before_each(create_test_buffer)

  it("should select word", function()
    execute_keys("<c-v>w<esc>")
    local region = utils.get_regions(vim.fn.visualmode())

    assert.are.same({ { start_row = 1, start_col = 0, end_row = 1, end_col = 6 } }, region)
  end)

  it("should select on 2 lines", function()
    execute_keys("<c-v>wj<esc>")
    local region = utils.get_regions(vim.fn.visualmode())

    assert.are.same({
      { start_row = 1, start_col = 0, end_row = 1, end_col = 6 },
      { start_row = 2, start_col = 0, end_row = 2, end_col = 6 },
    }, region)
  end)

  it("should select to the end of lines", function()
    execute_keys("wj")
    execute_keys("<c-v>j$<esc>")
    local region = utils.get_regions(vim.fn.visualmode())

    assert.are.same({
      { start_row = 2, start_col = 6, end_row = 2, end_col = 27 },
      { start_row = 3, start_col = 6, end_row = 3, end_col = 40 },
    }, region)
  end)

  it("should select from the beginning of lines", function()
    execute_keys("<c-v>jjl<esc>")
    local region = utils.get_regions(vim.fn.visualmode())

    assert.are.same({
      { start_row = 1, start_col = 0, end_row = 1, end_col = 1 },
      { start_row = 2, start_col = 0, end_row = 2, end_col = 1 },
      { start_row = 3, start_col = 0, end_row = 3, end_col = 1 },
    }, region)
  end)
end)

describe("Get text", function()
  before_each(create_test_buffer)

  it("should get one word at the beginning", function()
    local text = utils.get_text({ { start_row = 1, start_col = 0, end_row = 1, end_col = 4 } })

    assert.are.same({ "Lorem" }, text)
  end)

  it("should get one word", function()
    local text = utils.get_text({ { start_row = 1, start_col = 6, end_row = 1, end_col = 10 } })

    assert.are.same({ "ipsum" }, text)
  end)

  it("should get one word at the end", function()
    local text = utils.get_text({ { start_row = 2, start_col = 23, end_row = 2, end_col = 27 } })

    assert.are.same({ "elit." }, text)
  end)

  it("should get text on 2 lines", function()
    local text = utils.get_text({ { start_row = 1, start_col = 6, end_row = 2, end_col = 21 } })

    assert.are.same({ "ipsum dolor sit amet,", "consectetur adipiscing" }, text)
  end)

  it("should get text on 2 regions", function()
    local text = utils.get_text({
      { start_row = 1, start_col = 6, end_row = 1, end_col = 10 },
      { start_row = 2, start_col = 23, end_row = 2, end_col = 27 },
    })

    assert.are.same({ "ipsum", "elit." }, text)
  end)
end)

describe("Compare regions", function()
  before_each(create_test_buffer)

  it("Should return < if before", function()
    local cmp = utils.compare_regions(
      { {
        start_row = 0,
        start_col = 0,
        end_row = 1,
        end_col = 5,
      } },
      { {
        start_row = 2,
        start_col = 0,
        end_row = 3,
        end_col = 5,
      } }
    )

    assert.are.equal("<", cmp)

    cmp = utils.compare_regions(
      { {
        start_row = 0,
        start_col = 0,
        end_row = 1,
        end_col = 5,
      } },
      { {
        start_row = 1,
        start_col = 6,
        end_row = 3,
        end_col = 5,
      } }
    )

    assert.are.equal("<", cmp)
  end)

  it("Should return > if after", function()
    local cmp = utils.compare_regions(
      { {
        start_row = 2,
        start_col = 0,
        end_row = 3,
        end_col = 5,
      } },
      { {
        start_row = 0,
        start_col = 0,
        end_row = 1,
        end_col = 5,
      } }
    )

    assert.are.equal(">", cmp)

    cmp = utils.compare_regions(
      { {
        start_row = 1,
        start_col = 6,
        end_row = 3,
        end_col = 5,
      } },
      { {
        start_row = 0,
        start_col = 0,
        end_row = 1,
        end_col = 5,
      } }
    )

    assert.are.equal(">", cmp)
  end)

  it("Should return [ if origin includes target", function()
    local cmp = utils.compare_regions(
      { {
        start_row = 0,
        start_col = 0,
        end_row = 3,
        end_col = 6,
      } },
      { {
        start_row = 2,
        start_col = 0,
        end_row = 2,
        end_col = 5,
      } }
    )

    assert.are.equal("[", cmp)

    cmp = utils.compare_regions(
      { {
        start_row = 0,
        start_col = 6,
        end_row = 2,
        end_col = 4,
      } },
      { {
        start_row = 0,
        start_col = 7,
        end_row = 2,
        end_col = 3,
      } }
    )

    assert.are.equal("[", cmp)
  end)

  it("Should return ] if target includes origin", function()
    local cmp = utils.compare_regions(
      { {
        start_row = 2,
        start_col = 0,
        end_row = 2,
        end_col = 5,
      } },
      { {
        start_row = 0,
        start_col = 0,
        end_row = 3,
        end_col = 6,
      } }
    )

    assert.are.equal("]", cmp)

    cmp = utils.compare_regions(
      { {
        start_row = 0,
        start_col = 7,
        end_row = 2,
        end_col = 3,
      } },
      { {
        start_row = 0,
        start_col = 6,
        end_row = 2,
        end_col = 4,
      } }
    )

    assert.are.equal("]", cmp)
  end)

  it("Should return = if overlap", function()
    local cmp = utils.compare_regions(
      { {
        start_row = 1,
        start_col = 0,
        end_row = 3,
        end_col = 5,
      } },
      { {
        start_row = 2,
        start_col = 0,
        end_row = 4,
        end_col = 5,
      } }
    )

    assert.are.equal("=", cmp)

    cmp = utils.compare_regions(
      { {
        start_row = 2,
        start_col = 0,
        end_row = 2,
        end_col = 2,
      } },
      { {
        start_row = 2,
        start_col = 1,
        end_row = 2,
        end_col = 3,
      } }
    )

    assert.are.equal("=", cmp)

    cmp = utils.compare_regions(
      { {
        start_row = 2,
        start_col = 1,
        end_row = 2,
        end_col = 3,
      } },
      { {
        start_row = 2,
        start_col = 0,
        end_row = 2,
        end_col = 2,
      } }
    )

    assert.are.equal("=", cmp)
  end)
end)

describe("Substitute text", function()
  before_each(create_test_buffer)

  it("should substitute lines", function() end)
end)
