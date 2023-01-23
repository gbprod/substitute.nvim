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

  vim.keymap.set("n", "ss", "<cmd>lua require('substitute').line()<cr>", { noremap = true })
  vim.keymap.set("n", "S", "<cmd>lua require('substitute').eol()<cr>", { noremap = true })
  vim.keymap.set("n", "s", "<cmd>lua require('substitute').operator()<cr>", { noremap = true })
  vim.keymap.set("x", "s", "<cmd>lua require('substitute').visual()<cr>", { noremap = true })

  vim.keymap.set("n", "<leader>s", "<cmd>lua require('substitute.range').operator()<cr>", { noremap = true })

  vim.keymap.set("n", "sx", "<cmd>lua require('substitute.exchange').operator()<cr>", { noremap = true })
  vim.keymap.set("x", "X", "<cmd>lua require('substitute.exchange').visual()<cr>", { noremap = true })
end

M.setup()
