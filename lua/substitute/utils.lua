local utils = {}

function utils.get_regions(vmode)
  if vmode == vim.api.nvim_replace_termcodes("<c-v>", true, false, true) then
    local start = vim.api.nvim_buf_get_mark(0, "<")
    local finish = vim.api.nvim_buf_get_mark(0, ">")

    local regions = {}

    for row = start[1], finish[1], 1 do
      local current_row_len = vim.fn.getline(row):len() - 1

      table.insert(regions, {
        start_row = row,
        start_col = start[2],
        end_row = row,
        end_col = current_row_len >= finish[2] and finish[2] or current_row_len,
      })
    end

    return regions
  end

  local start_mark, end_mark = "[", "]"
  if vmode:match("[vV]") then
    start_mark, end_mark = "<", ">"
  end

  local start = vim.api.nvim_buf_get_mark(0, start_mark)
  local finish = vim.api.nvim_buf_get_mark(0, end_mark)
  local end_row_len = vim.fn.getline(finish[1]):len() - 1

  return {
    {
      start_row = start[1],
      start_col = start[2],
      end_row = finish[1],
      end_col = end_row_len >= finish[2] and finish[2] or end_row_len,
    },
  }
end

function utils.get_text(regions)
  local all_lines = {}
  for _, region in ipairs(regions) do
    local lines = vim.api.nvim_buf_get_lines(0, region.start_row - 1, region.end_row, true)
    lines[vim.tbl_count(lines)] = string.sub(lines[vim.tbl_count(lines)], 0, region.end_col + 1)
    lines[1] = string.sub(lines[1], region.start_col + 1)

    for _, line in ipairs(lines) do
      table.insert(all_lines, line)
    end
  end

  return all_lines
end

function utils.get_default_register()
  local clipboardFlags = vim.split(vim.api.nvim_get_option("clipboard"), ",")

  if vim.tbl_contains(clipboardFlags, "unnamedplus") then
    return "+"
  end

  if vim.tbl_contains(clipboardFlags, "unnamed") then
    return "*"
  end

  return '"'
end

function utils.get_register_type(vmode)
  if vmode == vim.api.nvim_replace_termcodes("<c-v>", true, false, true) then
    return "b"
  end

  if vmode == "V" then
    return "l"
  end

  return "c"
end

return utils
