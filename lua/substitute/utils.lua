local utils = {}

function utils.get_marks(bufnr, vmode)
  local start_mark, finish_mark = "[", "]"
  if utils.is_visual(vmode) then
    start_mark, finish_mark = "<", ">"
  end

  local pos_start = vim.api.nvim_buf_get_mark(bufnr, start_mark)
  local pos_finish = vim.api.nvim_buf_get_mark(bufnr, finish_mark)

  return {
    start = {
      row = pos_start[1],
      col = pos_start[2],
    },
    finish = {
      row = pos_finish[1],
      col = pos_finish[2],
    },
  }
end

function utils.substitute_text(bufnr, start, finish, regtype, replacement, replacement_regtype)
  regtype = utils.get_register_type(regtype)

  if "l" == regtype then
    vim.api.nvim_buf_set_lines(bufnr, start.row - 1, finish.row, false, replacement)

    local end_mark_col = string.len(replacement[#replacement]) + 1
    local end_mark_row = start.row + vim.tbl_count(replacement) - 1

    return { { start = { row = start.row, col = 0 }, finish = { row = end_mark_row, col = end_mark_col } } }
  end

  if utils.is_blockwise(regtype) then
    if utils.is_blockwise(replacement_regtype) then
      local marks = {}
      for row = start.row, finish.row, 1 do
        if start.col > finish.col then
          start.col, finish.col = finish.col, start.col
        end
        local current_row_len = vim.fn.getline(row):len()
        local last_replacement = table.remove(replacement, 1) or ""
        if current_row_len > 0 then
          vim.api.nvim_buf_set_text(
            bufnr,
            row - 1,
            start.col,
            row - 1,
            current_row_len > finish.col and finish.col + 1 or current_row_len,
            { last_replacement }
          )

          table.insert(marks, {
            start = { row = row, col = start.col },
            finish = { row = row, col = start.col + string.len(last_replacement) },
          })
        end
      end

      return marks
    end

    local marks = {}
    for row = finish.row, start.row, -1 do
      local current_row_len = vim.fn.getline(row):len()
      if start.col > finish.col then
        start.col, finish.col = finish.col, start.col
      end

      if current_row_len > 0 then
        vim.api.nvim_buf_set_text(
          bufnr,
          row - 1,
          current_row_len > start.col and start.col or current_row_len,
          row - 1,
          current_row_len > finish.col and finish.col + 1 or current_row_len,
          replacement
        )

        local end_mark_col = string.len(replacement[#replacement])
        if vim.tbl_count(replacement) == 1 then
          end_mark_col = end_mark_col + start.col
        end
        table.insert(marks, 1, {
          start = { row = row, col = start.col },
          finish = { row = row, col = end_mark_col },
        })
      end
    end

    return marks
  end

  local current_row_len = vim.fn.getline(finish.row):len()
  vim.api.nvim_buf_set_text(
    bufnr,
    start.row - 1,
    start.col,
    finish.row - 1,
    current_row_len > finish.col and finish.col + 1 or current_row_len,
    replacement
  )

  local end_mark_col = string.len(replacement[#replacement])
  if vim.tbl_count(replacement) == 1 then
    end_mark_col = end_mark_col + start.col
  end
  local end_mark_row = start.row + vim.tbl_count(replacement) - 1

  return { { start = start, finish = { row = end_mark_row, col = end_mark_col } } }
end

function utils.text(bufnr, start, finish, vmode)
  local regtype = utils.get_register_type(vmode)
  if "l" == regtype then
    return vim.api.nvim_buf_get_lines(bufnr, start.row - 1, finish.row, false)
  end

  if "b" == regtype then
    local text = {}
    for row = start.row, finish.row, 1 do
      local current_row_len = vim.fn.getline(row):len()

      local end_col = current_row_len > finish.col and finish.col + 1 or current_row_len
      if start.col > end_col then
        end_col = start.col
      end

      local lines = vim.api.nvim_buf_get_text(bufnr, row - 1, start.col, row - 1, end_col, {})

      for _, line in pairs(lines) do
        table.insert(text, line)
      end
    end

    return text
  end

  return vim.api.nvim_buf_get_text(0, start.row - 1, start.col, finish.row - 1, finish.col + 1, {})
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
  if utils.is_blockwise(vmode) or "b" == vmode then
    return "b"
  end

  if vmode == "V" or vmode == "line" or vmode == "l" then
    return "l"
  end

  return "c"
end

function utils.is_visual(vmode)
  return vmode:match("[vV]") or utils.is_blockwise(vmode)
end

function utils.is_blockwise(vmode)
  return vmode:byte() == 22 or vmode == "block" or vmode == "b"
end

-- Returns
--  < if origin comes before target
--  > if origin comes after target
--  [ if origin includes target
--  ] if origin is included in target
--  = if origin and target overlap
function utils.compare_regions(origin, target)
  if origin.regtype == "b" or target.regtype == "b" then
    vim.notify("Exchange doesn't works with blockwise selections", vim.log.levels.INFO, {})
    return "="
  end

  if origin.regtype == "l" then
    origin.marks.start.col = 0
    origin.marks.finish.col = vim.fn.getline(origin.marks.finish.row):len()
  end

  if target.regtype == "l" then
    target.marks.start.col = 0
    target.marks.finish.col = vim.fn.getline(target.marks.finish.row):len()
  end

  local origin_offset = {
    start = vim.api.nvim_buf_get_offset(0, origin.marks.start.row - 1) + origin.marks.start.col,
    finish = vim.api.nvim_buf_get_offset(0, origin.marks.finish.row - 1) + origin.marks.finish.col,
  }

  local target_offset = {
    start = vim.api.nvim_buf_get_offset(0, target.marks.start.row - 1) + target.marks.start.col,
    finish = vim.api.nvim_buf_get_offset(0, target.marks.finish.row - 1) + target.marks.finish.col,
  }

  --  < if origin comes before target
  if origin_offset.finish < target_offset.start then
    return "<"
  end

  --  > if origin comes after target
  if origin_offset.start > target_offset.finish then
    return ">"
  end

  --  [ if origin includes target
  if origin_offset.start <= target_offset.start and origin_offset.finish >= target_offset.finish then
    return "["
  end

  --  ] if origin includes target
  if target_offset.start <= origin_offset.start and target_offset.finish >= origin_offset.finish then
    return "]"
  end

  return "="
end

return utils
