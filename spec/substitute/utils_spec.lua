local utils = require("substitute.utils")

local function create_test_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_command("buffer " .. bufnr)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, {
    "Lorem ipsum dolor sit amet,",
    "consectetur adipiscing elit.",
    "Nulla malesuada lacus at ornare accumsan.",
    "",
    "Arcu dui vivamus arcu felis bibendum ut tristique et.",
    "Amet purus gravida quis blandit turpis cursus in.",
    "Auctor eu augue ut lectus arcu bibendum at.",
  })
end

describe("Get text", function()
  before_each(create_test_buffer)

  it("should get one word", function()
    local text = utils.text(0, { row = 1, col = 0 }, { row = 1, col = 4 }, "c")

    assert.are.same({ "Lorem" }, text)
  end)

  it("should get lines", function()
    local text = utils.text(0, { row = 2, col = 0 }, { row = 3, col = 4 }, "l")

    assert.are.same({ "consectetur adipiscing elit.", "Nulla malesuada lacus at ornare accumsan." }, text)
  end)

  it("should get columns", function()
    local text = utils.text(0, { row = 2, col = 1 }, { row = 3, col = 5 }, "b")

    assert.are.same({ "onsec", "ulla " }, text)
  end)
end)

describe("Compare regions", function()
  before_each(create_test_buffer)

  it("Should return < if before", function()
    local cmp = utils.compare_regions({
      regtype = "c",
      marks = {
        start = {
          row = 1,
          col = 0,
        },
        finish = {
          row = 2,
          col = 5,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 3,
          col = 0,
        },
        finish = {
          row = 5,
          col = 5,
        },
      },
    })

    assert.are.equal("<", cmp)

    cmp = utils.compare_regions({
      regtype = "c",
      marks = {
        start = {
          row = 1,
          col = 0,
        },
        finish = {
          row = 2,
          col = 5,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 2,
          col = 6,
        },
        finish = {
          row = 5,
          col = 5,
        },
      },
    })

    assert.are.equal("<", cmp)

    cmp = utils.compare_regions({
      regtype = "l",
      marks = {
        start = {
          row = 1,
          col = 0,
        },
        finish = {
          row = 2,
          col = 5,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 3,
          col = 6,
        },
        finish = {
          row = 5,
          col = 5,
        },
      },
    })

    assert.are.equal("<", cmp)
  end)

  it("Should return > if after", function()
    local cmp = utils.compare_regions({
      regtype = "c",
      marks = {
        start = {
          row = 3,
          col = 0,
        },
        finish = {
          row = 5,
          col = 5,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 1,
          col = 0,
        },
        finish = {
          row = 2,
          col = 5,
        },
      },
    })

    assert.are.equal(">", cmp)

    cmp = utils.compare_regions({
      regtype = "c",
      marks = {
        start = {
          row = 2,
          col = 6,
        },
        finish = {
          row = 5,
          col = 5,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 1,
          col = 0,
        },
        finish = {
          row = 2,
          col = 5,
        },
      },
    })

    assert.are.equal(">", cmp)

    cmp = utils.compare_regions({
      regtype = "l",
      marks = {
        start = {
          row = 3,
          col = 6,
        },
        finish = {
          row = 5,
          col = 5,
        },
      },
    }, {
      regtype = "l",
      marks = {
        start = {
          row = 1,
          col = 0,
        },
        finish = {
          row = 2,
          col = 5,
        },
      },
    })

    assert.are.equal(">", cmp)
  end)

  it("Should return [ if origin includes target", function()
    local cmp = utils.compare_regions({
      regtype = "c",
      marks = {
        start = {
          row = 1,
          col = 0,
        },
        finish = {
          row = 3,
          col = 6,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 2,
          col = 0,
        },
        finish = {
          row = 2,
          col = 5,
        },
      },
    })

    assert.are.equal("[", cmp)

    cmp = utils.compare_regions({
      regtype = "c",
      marks = {
        start = {
          row = 1,
          col = 6,
        },
        finish = {
          row = 3,
          col = 4,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 1,
          col = 7,
        },
        finish = {
          row = 3,
          col = 3,
        },
      },
    })

    assert.are.equal("[", cmp)
  end)

  it("Should return ] if target includes origin", function()
    local cmp = utils.compare_regions({
      regtype = "c",
      marks = {
        start = {
          row = 2,
          col = 0,
        },
        finish = {
          row = 2,
          col = 5,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 1,
          col = 0,
        },
        finish = {
          row = 3,
          col = 6,
        },
      },
    })

    assert.are.equal("]", cmp)

    cmp = utils.compare_regions({
      regtype = "c",
      marks = {
        start = {
          row = 1,
          col = 7,
        },
        finish = {
          row = 2,
          col = 3,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 1,
          col = 7,
        },
        finish = {
          row = 2,
          col = 4,
        },
      },
    })

    assert.are.equal("]", cmp)
  end)

  it("Should return = if overlap", function()
    local cmp = utils.compare_regions({
      regtype = "c",
      marks = {
        start = {
          row = 1,
          col = 0,
        },
        finish = {
          row = 3,
          col = 5,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 2,
          col = 0,
        },
        finish = {
          row = 5,
          col = 5,
        },
      },
    })

    assert.are.equal("=", cmp)

    cmp = utils.compare_regions({
      regtype = "c",
      marks = {
        start = {
          row = 2,
          col = 0,
        },
        finish = {
          row = 2,
          col = 2,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 2,
          col = 1,
        },
        finish = {
          row = 2,
          col = 3,
        },
      },
    })

    assert.are.equal("=", cmp)

    cmp = utils.compare_regions({
      regtype = "c",
      marks = {
        start = {
          row = 2,
          col = 1,
        },
        finish = {
          row = 2,
          col = 3,
        },
      },
    }, {
      regtype = "c",
      marks = {
        start = {
          row = 2,
          col = 0,
        },
        finish = {
          row = 2,
          col = 2,
        },
      },
    })

    assert.are.equal("=", cmp)
  end)
end)

describe("Substitute text", function()
  before_each(create_test_buffer)

  it("should substitute lines", function()
    utils.substitute_text(0, { row = 2, col = 5 }, { row = 3, col = 6 }, "l", { "Test" }, "c")

    local result = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)

    assert.are.same({
      "Lorem ipsum dolor sit amet,",
      "Test",
      "",
      "Arcu dui vivamus arcu felis bibendum ut tristique et.",
      "Amet purus gravida quis blandit turpis cursus in.",
      "Auctor eu augue ut lectus arcu bibendum at.",
    }, result)
  end)

  it("should substitute chars", function()
    utils.substitute_text(0, { row = 2, col = 5 }, { row = 3, col = 6 }, "c", { "Test" }, "c")

    local result = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)

    assert.are.same({
      "Lorem ipsum dolor sit amet,",
      "conseTestalesuada lacus at ornare accumsan.",
      "",
      "Arcu dui vivamus arcu felis bibendum ut tristique et.",
      "Amet purus gravida quis blandit turpis cursus in.",
      "Auctor eu augue ut lectus arcu bibendum at.",
    }, result)
  end)

  it("should substitute block", function()
    utils.substitute_text(0, { row = 2, col = 5 }, { row = 3, col = 6 }, "b", { "Test" }, "c")

    local result = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)

    assert.are.same({
      "Lorem ipsum dolor sit amet,",
      "conseTestetur adipiscing elit.",
      "NullaTestalesuada lacus at ornare accumsan.",
      "",
      "Arcu dui vivamus arcu felis bibendum ut tristique et.",
      "Amet purus gravida quis blandit turpis cursus in.",
      "Auctor eu augue ut lectus arcu bibendum at.",
    }, result)
  end)

  it("should substitute block with block", function()
    utils.substitute_text(0, { row = 2, col = 5 }, { row = 3, col = 6 }, "b", { "Test" }, "b")

    local result = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)

    assert.are.same({
      "Lorem ipsum dolor sit amet,",
      "conseTestetur adipiscing elit.",
      "Nullaalesuada lacus at ornare accumsan.",
      "",
      "Arcu dui vivamus arcu felis bibendum ut tristique et.",
      "Amet purus gravida quis blandit turpis cursus in.",
      "Auctor eu augue ut lectus arcu bibendum at.",
    }, result)
  end)

  it("should substitute block with block", function()
    utils.substitute_text(0, { row = 2, col = 5 }, { row = 3, col = 6 }, "b", { "Test", "TTTT", "RRRR" }, "b")

    local result = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)

    assert.are.same({
      "Lorem ipsum dolor sit amet,",
      "conseTestetur adipiscing elit.",
      "NullaTTTTalesuada lacus at ornare accumsan.",
      "",
      "Arcu dui vivamus arcu felis bibendum ut tristique et.",
      "Amet purus gravida quis blandit turpis cursus in.",
      "Auctor eu augue ut lectus arcu bibendum at.",
    }, result)
  end)
end)
