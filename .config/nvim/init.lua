-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Failed to clone lazy.nvim")
  end
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
-- NOTE
-- install nerdfonts: https://www.nerdfonts.com/font-downloads
-- =============================================================================

-- =============================================================================
-- General Options
-- =============================================================================
vim.opt.guifont = 'Source Code Pro'  -- Hack
vim.opt.cursorline = true
vim.opt.background = 'dark'
vim.opt.backup = false
vim.opt.fileformats = 'unix'
vim.opt.fileencodings = 'ucs-bom,utf-8,gbk,big5,latin1'
vim.opt.foldlevel = 99
vim.opt.autoread = true
vim.opt.wrap = false

local cargo_bin = vim.fs.joinpath(vim.env.HOME, ".cargo", "bin")
local path_entries = vim.split(vim.env.PATH or "", ":", { plain = true, trimempty = true })
if not vim.tbl_contains(path_entries, cargo_bin) then
  vim.env.PATH = vim.env.PATH and (vim.env.PATH .. ":" .. cargo_bin) or cargo_bin
end

local filetype_group = vim.api.nvim_create_augroup("UserFileType", { clear = true })

-- 补全相关选项
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.pumheight = 15

-- Set leader key
-- vim.g.mapleader = " "

-- Neovide specific settings
if vim.g.neovide then
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_scroll_animation_length = 0
end

-- =============================================================================
-- Key Mappings
-- =============================================================================
-- Tab navigation
vim.keymap.set('n', 'tn', ':tabnew<CR>', { desc = "New Tab" })
vim.keymap.set('n', 'tc', ':tabclose<CR>', { desc = "Close Tab" })
vim.keymap.set('n', 'tl', ':tabnext<CR>', { desc = "Next Tab" })
vim.keymap.set('n', 'th', ':tabprev<CR>', { desc = "Previous Tab" })

-- Mac map (if you are on macOS)
if vim.fn.has('macunix') == 1 then
  vim.keymap.set('n', '<D-c>', '"+y')
  vim.keymap.set('v', '<D-c>', '"+y')
  vim.keymap.set('n', '<D-x>', '"+x')
  vim.keymap.set('v', '<D-x>', '"+x')
  vim.keymap.set(
    {'n', 'v', 's', 'x', 'o', 'i', 'l', 'c', 't'},
    '<D-v>',
    function() vim.api.nvim_paste(vim.fn.getreg('+'), true, -1) end,
    { silent = true }
  )
end

if vim.fn.has('linux') == 1 then
  vim.keymap.set('v', '<C-c>', '"+y')
  vim.keymap.set('n', '<C-v>', '"+p')
  vim.keymap.set('i', '<C-v>', '<C-r>+')
  vim.keymap.set('n', '<C-x>', '"+dd')
  vim.keymap.set('v', '<C-x>', '"+d')
end

-- Disable horizontal scroll with mouse
vim.keymap.set('n', '<ScrollWheelRight>', '<Nop>')
vim.keymap.set('n', '<ScrollWheelLeft>', '<Nop>')

-- =============================================================================
-- Autocmds
-- =============================================================================
vim.api.nvim_create_autocmd("FileType", {
  group = filetype_group,
  pattern = "lua",
  callback = function()
    vim.opt_local.ts = 2
    vim.opt_local.sw = 2
    vim.opt_local.et = true
  end,
})

-- =============================================================================
-- Diagnostics Configuration
-- =============================================================================
local signs = {
  [vim.diagnostic.severity.ERROR] = " ",
  [vim.diagnostic.severity.WARN] = " ",
  [vim.diagnostic.severity.HINT] = "󰌵 ",
  [vim.diagnostic.severity.INFO] = " ",
}

vim.diagnostic.config({
  virtual_text = true,
  signs = {
    text = signs,
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
  },
})

-- =============================================================================
-- telescope-project options
-- 不做目录扫描：项目由用户在 picker 里手动加入——c 取当前 git 根，C 取当前 cwd，
-- 记录写在 stdpath('data')/telescope-projects.txt；d 只是停用（activated=0），不动磁盘。
-- 参数在下面的 telescope.setup({ extensions = ... }) 里注册，此处只声明一份。
-- =============================================================================
local function open_project_in_neotree(prompt_bufnr)
  local path = require("telescope._extensions.project.actions").get_selected_path(prompt_bufnr)
  require("telescope.actions").close(prompt_bufnr)
  vim.schedule(function()
    if vim.fn.isdirectory(path) == 0 then
      vim.notify("项目目录不存在: " .. path, vim.log.levels.WARN)
      return
    end
    require("neo-tree.command").execute({ source = "filesystem", dir = path })
  end)
end

local telescope_project = {
  hidden_files = true,        -- 与 <leader>ff 的 hidden 保持一致
  order_by = "recent",        -- 最近打开的优先，其余按标题
  cd_scope = { "tab", "window", "global" }, -- 按 o 在 tcd / lcd / cd 间轮换
  mappings = {
    -- b 默认依赖 telescope-file-browser（未安装），这里改成用 neo-tree 打开项目目录
    n = { b = open_project_in_neotree },
    i = { ["<c-b>"] = open_project_in_neotree },
  },
}

-- =============================================================================
-- Plugin Setup with Lazy.nvim
-- =============================================================================
require("lazy").setup({
  {
    'echasnovski/mini.icons',
    version = '*',
    opts = {},
  },
  {
    "hedyhli/outline.nvim",
    cmd = { "Outline", "OutlineOpen" },
    keys = {
      { "<leader>so", "<cmd>Outline<cr>", desc = "Symbols Outline" },
    },
    opts = {},
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },
  {
    "folke/tokyonight.nvim",
    priority = 1000,
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
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      local on_attach = function(_, bufnr)
        local opts = { buffer = bufnr, silent = true }
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
        vim.keymap.set('n', '[d', function()
          vim.diagnostic.jump({ count = -1, float = true })
        end, opts)
        vim.keymap.set('n', ']d', function()
          vim.diagnostic.jump({ count = 1, float = true })
        end, opts)
        vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
        vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
      end

      vim.lsp.config("*", {
        on_attach = on_attach,
        capabilities = capabilities,
      })
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' },
            },
          },
        },
      })
      -- pyright 只会在 PATH 里找 python3，不会自己发现项目里的虚拟环境。
      -- 项目根下有 pyrightconfig.json 时以它为准（venvPath/venv、extraPaths 都在里面配），
      -- 否则退化为在根目录找 .venv / venv 并把解释器告回去。
      local function pyright_python_path(root)
        if not root or vim.uv.fs_stat(root .. "/pyrightconfig.json") then
          return nil
        end
        for _, dir in ipairs({ ".venv", "venv" }) do
          local python = root .. "/" .. dir .. "/bin/python"
          if vim.uv.fs_stat(python) then
            return python
          end
        end
      end

      vim.lsp.config("pyright", {
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
        on_init = function(client)
          local root = client.config.root_dir
          local python = pyright_python_path(root)
          if not python then
            return
          end
          client.settings.python = vim.tbl_deep_extend(
            "force",
            client.settings.python or {},
            { pythonPath = python }
          )
          client:notify("workspace/didChangeConfiguration", { settings = client.settings })
        end,
      })
      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = {
              command = "clippy",
            },
          },
        },
      })

      require("mason").setup()
      -- v2 默认通过 vim.lsp.enable() 启用所有已安装的服务器。
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "rust_analyzer", "ts_ls" },
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
      telescope.setup({
        pickers = {
          find_files = {
            hidden = true,
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          project = telescope_project,
        },
      })
      telescope.load_extension('fzf')
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate", -- 需要 tree-sitter-cli 0.26.1+
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.setup({})
      vim.treesitter.language.register("json", { "jsonc" })
      treesitter.install({
        "bash", "bibtex", "c", "c_sharp", "cpp", "css", "csv", "dockerfile",
        "editorconfig", "git_config", "gitignore", "go", "hcl", "html",
        "htmldjango", "ini", "javascript", "json", "lua", "make",
        "markdown", "markdown_inline", "nginx", "perl", "po", "python",
        "requirements", "rst", "rust", "sql", "toml", "tsx", "typescript",
        "vim", "vimdoc", "xml", "yaml",
      })

      -- 保留原来的自动安装与高亮行为。
      local available = {}
      for _, lang in ipairs(treesitter.get_available()) do
        available[lang] = true
      end
      vim.api.nvim_create_autocmd("FileType", {
        group = filetype_group,
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang or not available[lang] or pcall(vim.treesitter.start, args.buf, lang) then
            return
          end
          treesitter.install(lang):await(function(err, installed)
            if not err and installed and vim.api.nvim_buf_is_valid(args.buf)
                and vim.bo[args.buf].filetype == args.match then
              pcall(vim.treesitter.start, args.buf, lang)
            end
          end)
        end,
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    opts = {},
  },
  {
    "akinsho/toggleterm.nvim",
    keys = {
      { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Toggle Terminal" },
    },
    opts = {},
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      -- diffview 用来承载 Neogit 的 diff 视图（s 键），没有它也能用内置 diff。
      "sindrets/diffview.nvim",
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit Status" },
      { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit Commit" },
      { "<leader>gL", "<cmd>Neogit log<cr>", desc = "Neogit Log" },
    },
    opts = {
      -- 让 Neogit 的 select/input 走 telescope，与现有的 picker 体验一致。
      integrations = {
        telescope = true,
        diffview = true,
      },
      graph_style = "unicode",
      commit_editor = { kind = "split" },
    },
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
        completion = {
          autocomplete = {
            cmp.TriggerEvent.TextChanged,
          },
          completeopt = 'menu,menuone,noselect'
        },
        experimental = {
          ghost_text = true,
        }
      })

      vim.api.nvim_create_autocmd("InsertCharPre", {
        group = vim.api.nvim_create_augroup("UserCmp", { clear = true }),
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
    opts = {},
  },
  {
    'windwp/nvim-ts-autotag',
    opts = {},
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    event = "VeryLazy",
    opts = {},
  },
  {
    'nvim-telescope/telescope-project.nvim',
    dependencies = {
      'nvim-telescope/telescope.nvim',
    },
    keys = {
      {
        "<leader>fp",
        function()
          -- 只显示标题分不清重名项目（python-prompt-toolkit 之类），带上末两级路径。
          require("telescope").extensions.project.project({ display_type = "two-segment" })
        end,
        desc = "Switch Project",
      },
    },
    config = function()
      -- 扩展参数已在 telescope.setup 的 extensions.project 里给出，这里只做注册，
      -- 顺带让 :Telescope project 与命令补全可用。
      require("telescope").load_extension("project")
    end,
  },
})
