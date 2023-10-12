local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.api.nvim_set_option('cursorline', true)
vim.api.nvim_set_option('background', 'dark')
-- vim.cmd('colorscheme solarized')
vim.api.nvim_set_option('backup', false)
vim.api.nvim_set_option('autochdir', true)
vim.api.nvim_set_option('fileformats', 'unix')
vim.api.nvim_set_option('encoding', 'utf-8')
vim.api.nvim_set_option('fileencodings', 'ucs-bom,utf-8,gbk,big5,latin1')

-- tab navigation
vim.api.nvim_set_keymap('n', 'tn', ':tabnew<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', 'tc', ':tabclose<CR>', { noremap = true })

-- Allow copy paste in neovim
vim.api.nvim_set_keymap('n', '<D-v>', '"+p', { noremap = true })
vim.api.nvim_set_keymap('i', '<D-v>', '<C-R>+', { noremap = true })
vim.api.nvim_set_keymap('t', '<D-v>', '<C-R>+', { noremap = true })
vim.api.nvim_set_keymap('v', '<D-c>', '"+y<CR>', { noremap = true })
vim.api.nvim_set_keymap('v', '<D-x>', '"+x<CR>', { noremap = true })

require("lazy").setup(
{
  "williamboman/mason.nvim",
  {
    "ishan9299/nvim-solarized-lua",
    config = function()
      -- don't show the tabs so brightly
      vim.g.solarized_visibility = "low"
      vim.cmd('colorscheme solarized')
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason").setup {}
      require("mason-lspconfig").setup {}
    end,
  },
  {
    "neovim/nvim-lspconfig",
    -- npm i -g pyright
    config = function()
      -- require("lspconfig").pyright.setup{}
      -- require("lspconfig").tsserver.setup{}
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      'MunifTanjim/nui.nvim',
      'nvim-lua/plenary.nvim',
    },
    keys = {
      { "<leader>ft", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
    },
    config = function()
      require("neo-tree").setup()
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      -- brew install ripgrep
      'nvim-lua/plenary.nvim',
      'BurntSushi/ripgrep',
      'nvim-telescope/telescope-fzf-native.nvim',
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Telescope find_files" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Telescope buffers" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Telescope live_grep" },
    },
    config = function()
      require("telescope").setup()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      -- brew install tree-sitter
    },
    config = function()
      require("nvim-treesitter.configs").setup {
        ensure_installed = { "python" },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
        }
      }
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require("lualine").setup()
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    keys = {
      { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "ToggleTerm" },
    },
    opts = {}
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },
  {
    'L3MON4D3/LuaSnip',
    dependencies = {
      "rafamadriz/friendly-snippets"
    },
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      'hrsh7th/cmp-cmdline',
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
          end,
        },
        window = {
          -- completion = cmp.config.window.bordered(),
          -- documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' }, -- For luasnip users.
        }, {
          { name = 'buffer' },
        })
      })

      -- Set configuration for specific filetype.
      cmp.setup.filetype('gitcommit', {
        sources = cmp.config.sources({
          { name = 'git' }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
        }, {
          { name = 'buffer' },
        })
      })

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })

      -- Set up lspconfig.
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      require("lspconfig").pyright.setup {
        capabilities = capabilities
      }
      require("lspconfig").tsserver.setup {
        capabilities = capabilities
      }

    end,
  },
})

