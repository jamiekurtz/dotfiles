-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- turn off markdown conceal
vim.o.conceallevel = 0

-- Enable true colors, required for tokyonight
vim.opt.termguicolors = true

-- Set the colorscheme
vim.cmd.colorscheme("tokyonight")

-- turn off markdown conceal
vim.o.conceallevel = 0

vim.api.nvim_set_keymap(
  "n",
  "<leader>r",
  ':let @+=expand("%")<CR>',
  { noremap = true, silent = true, desc = "Copy relative path" }
)

-- Remap p in visual mode to delete into the black hole register and then paste
vim.keymap.set("x", "p", [["_dP]], { remap = false, silent = true })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "makefile",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 8
    vim.opt_local.shiftwidth = 8
    vim.opt_local.softtabstop = 0
  end,
})
