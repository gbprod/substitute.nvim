local utils = {}

function utils.get_regions(vmode)
  if utils.is_blockwise(vmode) then
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
  if utils.is_visual(vmode) then
    start_mark, end_mark = "<", ">"
  end

  local start = vim.api.nvim_buf_get_mark(0, start_mark)
  local finish = vim.api.nvim_buf_get_mark(0, end_mark)
  local end_row_len = vim.fn.getline(finish[1]):len() - 1

  return {
    {
      start_row = start[1],
      start_col = vmode ~= "line" and start[2] or 0,
      end_row = finish[1],
      end_col = (end_row_len >= finish[2] and vmode ~= "line") and finish[2] or end_row_len,
    },
  }
end

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

function utils.substitute_text(bufnr, start, finish, vmode, replacement, regtype)
  if "line" == vmode or "V" == vmode then
    vim.api.nvim_buf_set_lines(bufnr, start.row - 1, finish.row, false, replacement)

    return
  end

  if utils.is_blockwise(vmode) then
    if utils.is_blockwise(regtype) then
      for row = start.row, finish.row, 1 do
        local current_row_len = vim.fn.getline(row):len()
        if current_row_len > 0 then
          vim.api.nvim_buf_set_text(
            bufnr,
            row - 1,
            start.col,
            row - 1,
            current_row_len > finish.col and finish.col + 1 or current_row_len,
            { table.remove(replacement, 1) or "" }
          )
        end
      end

      return
    end

    for row = finish.row, start.row, -1 do
      local current_row_len = vim.fn.getline(row):len()
      if current_row_len > 0 then
        vim.api.nvim_buf_set_text(
          bufnr,
          row - 1,
          start.col,
          row - 1,
          current_row_len > finish.col and finish.col + 1 or current_row_len,
          replacement
        )
      end
    end

    return
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
end

function utils.text(bufnr, start, finish, vmode)
  if "line" == vmode or "V" == vmode then
    return vim.api.nvim_buf_get_lines(bufnr, start.row - 1, finish.row, false)
  end

  if utils.is_blockwise(vmode) then
    local text = {}
    for row = start.row, finish.row, 1 do
      local current_row_len = vim.fn.getline(row):len()

      local lines = vim.api.nvim_buf_get_text(
        bufnr,
        row - 1,
        start.col,
        row - 1,
        current_row_len > finish.col and finish.col + 1 or current_row_len,
        {}
      )

      for _, line in pairs(lines) do
        table.insert(text, line)
      end
    end

    return text
  end

  return vim.api.nvim_buf_get_text(0, start.row - 1, start.col, finish.row - 1, finish.col + 1, {})
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
  if utils.is_blockwise(vmode) then
    return "b"
  end

  if vmode == "V" then
    return "l"
  end

  return "c"
end

function utils.is_visual(vmode)
  return vmode:match("[vV]") or utils.is_blockwise(vmode)
end

function utils.is_blockwise(vmode)
  return vmode:byte() == 22
end

-- Returns
--  < if origin comes before target
--  > if origin comes after target
--  [ if origin includes target
--  ] if origin is included in target
--  = if origin and target overlap
function utils.compare_regions(origin_regions, target_regions)
  if vim.tbl_count(origin_regions) ~= 1 or vim.tbl_count(target_regions) ~= 1 then
    vim.notify("Exchange doesn't works with blockwise selections yet...", vim.log.levels.INFO, {})
    return "="
  end

  --  < if origin comes before target
  if
    origin_regions[1].end_row < target_regions[1].start_row
    or (
      origin_regions[1].end_row == target_regions[1].start_row
      and origin_regions[1].end_col < target_regions[1].start_col
    )
  then
    return "<"
  end

  --  > if origin comes after target
  if
    origin_regions[1].start_row > target_regions[1].end_row
    or (
      origin_regions[1].start_row == target_regions[1].end_row
      and origin_regions[1].start_col > target_regions[1].end_col
    )
  then
    return ">"
  end

  --  [ if origin includes target
  if
    (
      origin_regions[1].start_row < target_regions[1].start_row
      or (
        target_regions[1].start_row == origin_regions[1].start_row
        and origin_regions[1].start_col < target_regions[1].start_col
      )
    )
    and (
      origin_regions[1].end_row > target_regions[1].end_row
      or (
        target_regions[1].end_row == origin_regions[1].end_row
        and origin_regions[1].end_col > target_regions[1].end_col
      )
    )
  then
    return "["
  end

  --  ] if origin includes target
  if
    (
      target_regions[1].start_row < origin_regions[1].start_row
      or (
        target_regions[1].start_row == origin_regions[1].start_row
        and target_regions[1].start_col < origin_regions[1].start_col
      )
    )
    and (
      target_regions[1].end_row > origin_regions[1].end_row
      or (
        origin_regions[1].end_row == target_regions[1].end_row
        and target_regions[1].end_col > origin_regions[1].end_col
      )
    )
  then
    return "]"
  end

  return "="
end

function utils.highlight_regions(regions, hl_group, ns_id)
  for _, region in ipairs(regions) do
    for line = region.start_row, region.end_row do
      vim.api.nvim_buf_add_highlight(
        0,
        ns_id,
        hl_group,
        line - 1,
        line == region.start_row and region.start_col or 0,
        line == region.end_row and region.end_col + 1 or -1
      )
    end
  end
end

return utils
