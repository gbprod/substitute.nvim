local M = {}

function M.root(root)
  local f = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(f, ":p:h:h") .. "/" .. (root or "")
end

---@param plugin string
function M.load(plugin)
  local name = plugin:match(".*/(.*)")
  local package_root = M.root(".spec/site/pack/deps/start/")
  if not vim.loop.fs_stat(package_root .. name) then
    print("Installing " .. plugin)
    vim.fn.mkdir(package_root, "p")
    vim.fn.system({
      "git",
      "clone",
      "--depth=1",
      "https://github.com/" .. plugin .. ".git",
      package_root .. "/" .. name,
    })
  end
end

function M.setup()
  vim.cmd([[set runtimepath=$VIMRUNTIME]])
  vim.opt.runtimepath:append(M.root())
  vim.opt.packpath = { M.root(".spec/site") }

  M.load("nvim-lua/plenary.nvim")

  vim.keymap.set("n", "ss", require("substitute").line, { noremap = true })
  vim.keymap.set("n", "S", require("substitute").eol, { noremap = true })
  vim.keymap.set("n", "s", require("substitute").operator, { noremap = true })
  vim.keymap.set("x", "s", require("substitute").visual, { noremap = true })

  vim.keymap.set("n", "<leader>s", require("substitute.range").operator, { noremap = true })

  vim.keymap.set("n", "sx", require("substitute.exchange").operator, { noremap = true })
  vim.keymap.set("x", "X", require("substitute.exchange").visual, { noremap = true })
end

M.setup()
