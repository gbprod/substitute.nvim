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
      start_col = vmode ~= "line" and start[2] or 0,
      end_row = finish[1],
      end_col = (end_row_len >= finish[2] and vmode ~= "line") and finish[2] or end_row_len,
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
