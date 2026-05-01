-- ========================================================
-- Personal nvim config — minimal viewer/file-browser setup
-- AI does the coding (Claude Code in terminal).
-- nvim is for: opening files, browsing trees, reviewing diffs.
-- ========================================================

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- [[ Options ]]
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.clipboard = 'unnamedplus'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.signcolumn = 'yes'
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.undofile = true
vim.o.confirm = true
vim.o.inccommand = 'split'
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.expandtab = true
vim.o.colorcolumn = '80'
vim.o.autoread = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.timeoutlen = 300
vim.o.updatetime = 250

-- [[ Keymaps ]]
-- Clear search highlight on Esc
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<cr>')

-- jk to escape insert mode
vim.keymap.set('i', 'jk', '<Esc>')

-- Faster motions
vim.keymap.set({ 'n', 'v', 'o' }, 'H', '^')
vim.keymap.set({ 'n', 'v', 'o' }, 'L', '$')
vim.keymap.set({ 'n', 'v', 'o' }, 'J', '5j')
vim.keymap.set({ 'n', 'v', 'o' }, 'K', '5k')

-- Search same word under cursor
vim.keymap.set('n', ',', '#')
vim.keymap.set('n', '.', '*')

-- j/k move by display line
vim.keymap.set('n', 'j', "v:count ? 'j' : 'gj'", { expr = true })
vim.keymap.set('n', 'k', "v:count ? 'k' : 'gk'", { expr = true })

-- Toggle wrap
vim.keymap.set('n', 'zw', '<cmd>set wrap!<cr>')

-- Leader: save / line jumps
vim.keymap.set('n', '<leader>w', '<cmd>w<cr>')
vim.keymap.set('n', '<leader>q', '<cmd>q<cr>')
vim.keymap.set('n', '<leader>h', '^')
vim.keymap.set('n', '<leader>l', '$')
vim.keymap.set('n', '<leader>j', '40j')
vim.keymap.set('n', '<leader>k', '40k')

-- Paste in visual without overwriting register
vim.keymap.set('x', 'p', 'pgvy')
vim.keymap.set('x', 'P', 'Pgvy')

-- Window navigation (also handled by tmux-navigator across panes)
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- [[ Autocmds ]]
local aug = vim.api.nvim_create_augroup('user', { clear = true })

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = aug,
  callback = function() vim.hl.on_yank() end,
})

-- Restore last cursor position
vim.api.nvim_create_autocmd('BufReadPost', {
  group = aug,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Strip trailing whitespace on save
vim.api.nvim_create_autocmd('BufWritePre', {
  group = aug,
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd [[%s/\s\+$//e]]
    vim.fn.winrestview(view)
  end,
})

-- Auto-reload externally changed files
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  group = aug,
  command = 'silent! checktime',
})

-- [[ lazy.nvim bootstrap ]]
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system {
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- Colorscheme
  {
    'vague2k/vague.nvim',
    priority = 1000,
    config = function()
      require('vague').setup {}
      vim.cmd.colorscheme 'vague'
    end,
  },

  -- Syntax highlighting (read-only value: just for reading code)
  -- Pinned to master because the new `main` branch reorganized the module layout
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    lazy = false,
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
        'lua', 'vim', 'vimdoc', 'bash', 'python', 'javascript',
        'typescript', 'tsx', 'json', 'yaml', 'toml', 'html', 'css',
        'markdown', 'markdown_inline', 'go', 'rust',
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- File tree (sidebar)
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    cmd = 'Neotree',
    keys = {
      { '<leader>e', '<cmd>Neotree toggle<cr>', desc = 'Toggle file tree' },
      { '<leader>E', '<cmd>Neotree reveal<cr>', desc = 'Reveal current file in tree' },
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
      window = { width = 32 },
    },
  },

  -- File-as-buffer browser
  {
    'stevearc/oil.nvim',
    lazy = false,
    keys = {
      { '-', '<cmd>Oil<cr>', desc = 'Open parent dir in oil' },
    },
    opts = {
      view_options = { show_hidden = true },
    },
  },

  -- Fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = 'Telescope',
    keys = {
      { '<leader>o', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
      { '<leader>b', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
      { '<leader>g', '<cmd>Telescope live_grep<cr>', desc = 'Live grep' },
      { '<leader><leader>', '<cmd>Telescope oldfiles<cr>', desc = 'Recent files' },
    },
    opts = {},
  },

  -- Diff viewing for Claude Code edits
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
    keys = {
      { '<leader>dv', '<cmd>DiffviewOpen<cr>', desc = 'Open diffview' },
      { '<leader>dc', '<cmd>DiffviewClose<cr>', desc = 'Close diffview' },
      { '<leader>dh', '<cmd>DiffviewFileHistory %<cr>', desc = 'File history' },
    },
  },

  -- Motion
  { 'folke/flash.nvim', event = 'VeryLazy', opts = {} },

  -- Commenting (preserve old `'` mapping)
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
      vim.keymap.set('n', "'", 'gcc', { remap = true })
      vim.keymap.set('x', "'", 'gc', { remap = true })
    end,
  },

  -- Window/pane navigation across vim and tmux
  { 'christoomey/vim-tmux-navigator', lazy = false },

  -- Highlight other occurrences of word under cursor
  {
    'RRethy/vim-illuminate',
    event = 'VeryLazy',
    config = function()
      require('illuminate').configure {
        delay = 200,
        filetypes_denylist = { 'neo-tree', 'oil', 'TelescopePrompt', 'lazy' },
      }
    end,
  },
}, {
  ui = { border = 'rounded' },
})
