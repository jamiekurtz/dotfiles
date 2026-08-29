return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "default",

        ["<CR>"] = {}, -- disable Enter accepting completion

        ["<Tab>"] = {
          "select_and_accept",
          "fallback",
        },
      },
    },
  },
}
