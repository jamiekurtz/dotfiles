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

-- Emit Nerd Font glyphs. The font itself is only needed on the machine
-- drawing the pixels, never on a remote server -- neovim just sends the
-- codepoints and the local terminal resolves them.
vim.g.have_nerd_font = true

-- Over ssh there is no local clipboard to talk to, so route yanks through
-- OSC 52 and let the terminal put them on the clipboard of whatever machine
-- you are actually sitting at. On the workstations this block is skipped and
-- the normal wl-copy provider is used.
--
-- Paste is deliberately served from the unnamed register rather than read
-- back over OSC 52: most terminals refuse clipboard *reads* for security
-- reasons, so a read-based provider would just hang. Paste into the server
-- with the terminal's own paste instead.
if vim.env.SSH_TTY then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = function()
        return vim.fn.split(vim.fn.getreg(""), "\n")
      end,
      ["*"] = function()
        return vim.fn.split(vim.fn.getreg(""), "\n")
      end,
    },
  }
end
