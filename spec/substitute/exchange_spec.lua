local substitute = require("substitute")

local function execute_keys(feedkeys)
  local keys = vim.api.nvim_replace_termcodes(feedkeys, true, false, true)
  vim.api.nvim_feedkeys(keys, "x", false)
end

local function get_buf_lines()
  local result = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
  return result
end

local function create_test_buffer()
  substitute.setup()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_command("buffer " .. buf)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, {
    "Lorem ipsum dolor sit amet,",
    "consectetur adipiscing elit.",
    "Nulla malesuada lacus at ornare accumsan.",
  })
end

describe("Exchange", function()
  before_each(create_test_buffer)

  it("should exchange when target is after", function()
    execute_keys("sxiw")
    execute_keys("jj")
    execute_keys("sxiw")

    assert.are.same({
      "Nulla ipsum dolor sit amet,",
      "consectetur adipiscing elit.",
      "Lorem malesuada lacus at ornare accumsan.",
    }, get_buf_lines())
  end)

  it("should exchange when target is after on the same line", function()
    execute_keys("sxiw")
    execute_keys("ww")
    execute_keys("sxiw")

    assert.are.same({
      "dolor ipsum Lorem sit amet,",
      "consectetur adipiscing elit.",
      "Nulla malesuada lacus at ornare accumsan.",
    }, get_buf_lines())
  end)

  it("should exchange when target is before", function()
    execute_keys("jj")
    execute_keys("sxiw")
    execute_keys("kk")
    execute_keys("sxiw")

    assert.are.same({
      "Nulla ipsum dolor sit amet,",
      "consectetur adipiscing elit.",
      "Lorem malesuada lacus at ornare accumsan.",
    }, get_buf_lines())
  end)

  it("should exchange when target is before on the same line", function()
    execute_keys("ww")
    execute_keys("sxiw")
    execute_keys("bb")
    execute_keys("sxiw")

    assert.are.same({
      "dolor ipsum Lorem sit amet,",
      "consectetur adipiscing elit.",
      "Nulla malesuada lacus at ornare accumsan.",
    }, get_buf_lines())
  end)

  it("should exchange when target is included", function()
    execute_keys("sx2j")
    execute_keys("j")
    execute_keys("sxiw")

    assert.are.same({
      "consectetur",
    }, get_buf_lines())
  end)

  it("should exchange when target is included on the same line", function()
    execute_keys("sx5w")
    execute_keys("2w")
    execute_keys("sxiw")

    assert.are.same({
      "dolor,",
      "consectetur adipiscing elit.",
      "Nulla malesuada lacus at ornare accumsan.",
    }, get_buf_lines())
  end)

  it("should exchange when origin is included", function()
    execute_keys("j")
    execute_keys("sxiw")
    execute_keys("k")
    execute_keys("sx2j")

    assert.are.same({
      "consectetur",
    }, get_buf_lines())
  end)

  it("should exchange when origin is included on the same line", function()
    execute_keys("2w")
    execute_keys("sxiw")
    execute_keys("^")
    execute_keys("sx5w")

    assert.are.same({
      "dolor,",
      "consectetur adipiscing elit.",
      "Nulla malesuada lacus at ornare accumsan.",
    }, get_buf_lines())
  end)

  it("should do nothing if overlapping", function()
    execute_keys("sxj")
    execute_keys("k")
    execute_keys("sxj")

    assert.are.same({
      "Lorem ipsum dolor sit amet,",
      "consectetur adipiscing elit.",
      "Nulla malesuada lacus at ornare accumsan.",
    }, get_buf_lines())
  end)

  it("should do nothing if overlapping on the same line", function()
    execute_keys("sx2w")
    execute_keys("w")
    execute_keys("sx2w")

    assert.are.same({
      "Lorem ipsum dolor sit amet,",
      "consectetur adipiscing elit.",
      "Nulla malesuada lacus at ornare accumsan.",
    }, get_buf_lines())
  end)
end)
