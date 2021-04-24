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

return utils
