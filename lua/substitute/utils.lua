local utils = {}

function utils.get_region(vmode)
  local sln, eln
  if vmode:match("[vV]") then
    sln = vim.api.nvim_buf_get_mark(0, "<")
    eln = vim.api.nvim_buf_get_mark(0, ">")
  else
    sln = vim.api.nvim_buf_get_mark(0, "[")
    eln = vim.api.nvim_buf_get_mark(0, "]")
  end

  return {
    start_row = sln[1],
    start_col = sln[2],
    end_row = eln[1],
    end_col = math.min(eln[2], vim.fn.getline(eln[1]):len() - 1),
  }
end

function utils.nvim_buf_get_text(start_row, start_col, end_row, end_col)
  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, true)

  lines[vim.tbl_count(lines)] = string.sub(lines[vim.tbl_count(lines)], 0, end_col)
  lines[1] = string.sub(lines[1], start_col + 1)

  return lines
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
return utils
