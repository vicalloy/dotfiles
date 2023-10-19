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

-- https://github.com/adobe-fonts/source-code-pro
vim.opt.guifont = 'Source Code Pro'
vim.api.nvim_set_option('cursorline', true)
vim.api.nvim_set_option('background', 'dark')
vim.api.nvim_set_option('backup', false)
vim.api.nvim_set_option('autochdir', true)
vim.api.nvim_set_option('fileformats', 'unix')
vim.api.nvim_set_option('encoding', 'utf-8')
vim.api.nvim_set_option('fileencodings', 'ucs-bom,utf-8,gbk,big5,latin1')

-- neovide
if vim.g.neovide then
  vim.g.neovide_cursor_animation_length = 0
  vim.o.guifont = 'Source Code Pro'
end

-- tab navigation
vim.api.nvim_set_keymap('n', 'tn', ':tabnew<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', 'tc', ':tabclose<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', 'tl', ':tabnext<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', 'th', ':tabprev<CR>', { noremap = true })

-- Mac map
vim.cmd.source("$VIMRUNTIME/macmap.vim")

vim.api.nvim_command([[
autocmd Filetype lua setlocal ts=2 sw=2 et
]])


require("lazy").setup(
{
  "williamboman/mason.nvim",
  {
    "simrat39/symbols-outline.nvim",
    keys = {
      { "<leader>so", "<cmd>SymbolsOutline<cr>", desc = "SymbolsOutline" },
    },
    config = function()
      require("symbols-outline").setup {}
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {}
  },
  {
    "folke/tokyonight.nvim",
    config = function()
      require("tokyonight").setup({
        style = "moon",
      })
      if vim.fn.has("gui_running") ~= 0 then
        vim.cmd('colorscheme tokyonight')
      else
        vim.cmd("colorscheme tokyonight")
        -- vim.cmd("colorscheme default")
      end
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
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { "<leader>ft", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
    },
    config = function()
      require("neo-tree").setup({
        filesystem = {
          use_libuv_file_watcher = true,
          follow_current_file = {
            enabled = true,
          },
        },
      })
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
    build = "make install_jsregexp",
    config = function()
      require("lualine").setup()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
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
      local ls = require("luasnip")

      vim.keymap.set({"i"}, "<C-K>", function() ls.expand() end, {silent = true})
      vim.keymap.set({"i", "s"}, "<C-L>", function() ls.jump( 1) end, {silent = true})
      vim.keymap.set({"i", "s"}, "<C-J>", function() ls.jump(-1) end, {silent = true})

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
  {
    'mfussenegger/nvim-dap',
    config = function()
      local dap = require("dap")
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle breackpoint" })
      vim.keymap.set('n', '<F5>', dap.continue, { desc = "DAP: continue" })
      vim.keymap.set('n', '<F10>', dap.step_over, { desc = "DAP: step_over" })
      vim.keymap.set('n', '<F11>', dap.step_into, { desc = "DAP: step_into" })
      vim.keymap.set('n', '<F12>', dap.step_out, { desc = "DAP: step_out" })
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
    }
  },
  {
    'numToStr/Comment.nvim',
    opts = {
      -- `gc` to toggle comment
    },
    lazy = false,
  },
  {
    'windwp/nvim-ts-autotag',
    config = function()
      require('nvim-ts-autotag').setup()
    end,
  }
})

