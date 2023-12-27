return {
  {
    "pocco81/auto-save.nvim",
  },

  {
    "christoomey/vim-tmux-navigator",
    keys = {
      { "<c-h>" },
      { "<c-j>" },
      { "<c-k>" },
      { "<c-l>" },
    },
  },

  {
    "kqito/vim-easy-replace",
    keys = {
      { "r", ":<c-u>EasyReplaceWordInVisual<cr>", mode = "v" },
      { "R", ":<c-u>EasyReplaceCwordInVisual<cr>", mode = "v" },
    },
  },
}
