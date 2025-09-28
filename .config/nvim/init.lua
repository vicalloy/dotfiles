-- Bootstrap lazy.nvim
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

-- =============================================================================
-- NOTE
-- install nerdfonts: https://www.nerdfonts.com/font-downloads
-- =============================================================================

-- =============================================================================
-- General Options
-- =============================================================================
vim.opt.guifont = 'Source Code Pro'
vim.opt.cursorline = true
vim.opt.background = 'dark'
vim.opt.backup = false
vim.opt.fileformats = 'unix'
vim.opt.encoding = 'utf-8'
vim.opt.fileencodings = 'ucs-bom,utf-8,gbk,big5,latin1'
vim.opt.foldlevel = 99
vim.opt.autoread = true
vim.opt.wrap = false

-- 补全相关选项
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.pumheight = 15  -- 限制弹出菜单高度

-- Set leader key for which-key to see
vim.g.mapleader = " "

-- Neovide specific settings
if vim.g.neovide then
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_scroll_animation_length = 0
  vim.o.guifont = 'Source Code Pro'
end

-- =============================================================================
-- Key Mappings
-- =============================================================================
-- Tab navigation
vim.keymap.set('n', 'tn', ':tabnew<CR>', { noremap = true, desc = "New Tab" })
vim.keymap.set('n', 'tc', ':tabclose<CR>', { noremap = true, desc = "Close Tab" })
vim.keymap.set('n', 'tl', ':tabnext<CR>', { noremap = true, desc = "Next Tab" })
vim.keymap.set('n', 'th', ':tabprev<CR>', { noremap = true, desc = "Previous Tab" })

-- Mac map (if you are on macOS)
if vim.fn.has('macunix') == 1 then
  vim.cmd.source("$VIMRUNTIME/macmap.vim")
end

-- Disable horizontal scroll with mouse
vim.keymap.set('n', '<ScrollWheelRight>', '<Nop>', { noremap = true })
vim.keymap.set('n', '<ScrollWheelLeft>', '<Nop>', { noremap = true })

-- =============================================================================
-- Autocmds
-- =============================================================================
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  command = "setlocal ts=2 sw=2 et",
})

-- =============================================================================
-- Diagnostics Configuration (for Neovim 0.11+)
-- =============================================================================
-- Configure how diagnostics are displayed
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Change diagnostic signs to icons
local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end


-- =============================================================================
-- Plugin Setup with Lazy.nvim
-- =============================================================================
require("lazy").setup({
  { 'echasnovski/mini.nvim', version = '*' },
  { 'echasnovski/mini.icons', version = '*' },
  {
    "simrat39/symbols-outline.nvim",
    keys = {
      { "<leader>so", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" },
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
    priority = 1000, -- Make sure to load this before other plugins
    config = function()
      require("tokyonight").setup({
        style = "moon",
      })
      vim.cmd('colorscheme tokyonight')
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      'hrsh7th/cmp-nvim-lsp', -- For LSP completion capabilities
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      local on_attach = function(client, bufnr)
        local opts = { buffer = bufnr, noremap = true, silent = true }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
        vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
        vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
      end

      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright", "rust_analyzer", "ts_ls" }
      })

      require("mason-lspconfig").setup_handlers({
        -- 默认处理器：适用于所有未单独配置的 LSP
        function(server_name)
          lspconfig[server_name].setup {
            on_attach = on_attach,
            capabilities = capabilities,
          }
        end,

        -- 特殊配置：只对特定 LSP 覆盖默认行为
        ["lua_ls"] = function()
          lspconfig.lua_ls.setup {
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
              Lua = {
                diagnostics = {
                  globals = { 'vim' },
                },
              },
            },
          }
        end,

        ["pyright"] = function()
          lspconfig.pyright.setup {
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
              python = {
                analysis = {
                  typeCheckingMode = "basic",
                  autoSearchPaths = true,
                  useLibraryCodeForTypes = true,
                }
              }
            }
          }
        end,
      })

    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    keys = {
      { "<leader>ft", "<cmd>Neotree toggle<cr>", desc = "NeoTree Toggle" },
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
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find Buffers" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup()
      telescope.load_extension('fzf')
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup {
        ensure_installed = { "python", "c", "lua", "vim", "vimdoc", "javascript", "html", "rust" },
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
      { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Toggle Terminal" },
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
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      'hrsh7th/cmp-cmdline',
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp', priority = 1000 },
          { name = 'luasnip', priority = 750 },
        }, {
          { name = 'buffer', priority = 500 },
          { name = 'path', priority = 250 },
        }),
        -- 关键配置：启用自动补全
        completion = {
          autocomplete = {
            cmp.TriggerEvent.TextChanged,
          },
          completeopt = 'menu,menuone,noselect'
        },
        -- 自动触发字符
        experimental = {
          ghost_text = true, -- 显示预览文本
        }
      })

      -- 设置特定字符自动触发补全
      vim.api.nvim_create_autocmd("InsertCharPre", {
        callback = function()
          local char = vim.v.char
          if char == '.' then
            vim.schedule(function()
              cmp.complete()
            end)
          end
        end
      })

      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = 'buffer' } }
      })

      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = 'path' } }, { { name = 'cmdline' } })
      })
    end,
  },
  {
    'mfussenegger/nvim-dap',
    config = function()
      local dap = require("dap")
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle breakpoint" })
      vim.keymap.set('n', '<F5>', dap.continue, { desc = "DAP: Continue" })
      vim.keymap.set('n', '<F10>', dap.step_over, { desc = "DAP: Step Over" })
      vim.keymap.set('n', '<F11>', dap.step_into, { desc = "DAP: Step Into" })
      vim.keymap.set('n', '<F12>', dap.step_out, { desc = "DAP: Step Out" })
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {}
  },
  {
    'numToStr/Comment.nvim',
    opts = {},
    lazy = false,
  },
  {
    'windwp/nvim-ts-autotag',
    config = function()
      require('nvim-ts-autotag').setup()
    end,
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end
  },
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    event = "VeryLazy",
    config = function()
      require("ufo").setup({})
    end
  },
})

