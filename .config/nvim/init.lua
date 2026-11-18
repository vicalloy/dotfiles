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
vim.opt.guifont = 'SauceCodePro Nerd Font:h14'
vim.opt.cursorline = true
vim.opt.background = 'dark'
vim.opt.backup = false
vim.opt.fileformats = 'unix'
vim.opt.fileencodings = 'ucs-bom,utf-8,gbk,big5,latin1'
vim.opt.foldlevel = 99
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.autoread = true
vim.opt.wrap = false

-- GUI 启动（Neovide / Finder）拿不到 shell 的 PATH，这里保证 nvim 至少能找到
-- ~/.cargo/bin 和 ~/.local/bin（uv tool 装的 pyrefly 在后者）。
local extra_bins = {
  vim.fs.joinpath(vim.env.HOME, ".cargo", "bin"),
  vim.fs.joinpath(vim.env.HOME, ".local", "bin"),
}
local path_entries = vim.split(vim.env.PATH or "", ":", { plain = true, trimempty = true })
for _, bin in ipairs(extra_bins) do
  if not vim.tbl_contains(path_entries, bin) then
    vim.env.PATH = vim.env.PATH and (vim.env.PATH .. ":" .. bin) or bin
    table.insert(path_entries, bin)
  end
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
    -- lua 的兜底缩进；guess-indent 在 BufReadPost 之后按文件内容探测并覆盖
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
-- Inlay Hints / Undotree / LSP Progress（全部走 0.12 内置，不装插件）
-- =============================================================================
-- pyrefly / rust-analyzer 都支持 inlay hints
vim.lsp.inlay_hint.enable(true)
vim.keymap.set('n', '<leader>ih', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle Inlay Hints" })

-- 0.12 自带 nvim.undotree（pack/dist/opt）
vim.keymap.set('n', '<leader>u', function()
  vim.cmd.packadd('nvim.undotree')
  vim.cmd.Undotree()
end, { desc = "Undotree" })

-- LSP 进度事件触发 statusline 重绘，配合 lualine 的进度段，省掉 fidget
vim.api.nvim_create_autocmd('LspProgress', {
  group = vim.api.nvim_create_augroup('UserLspProgress', { clear = true }),
  callback = function() vim.cmd.redrawstatus() end,
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
    'nvim-mini/mini.icons',
    version = '*',
    config = function()
      require('mini.icons').setup({})
      -- 让只认 nvim-web-devicons 的插件（neo-tree / lualine）继续拿到图标
      require('mini.icons').mock_nvim_web_devicons()
    end,
  },
  {
    -- 按文件内容探测缩进，覆盖默认值；lua 的 2 空格仍由 FileType autocmd 兜底
    'NMAC427/guess-indent.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
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
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '[d', function()
          vim.diagnostic.jump({ count = -1, float = true })
        end, opts)
        vim.keymap.set('n', ']d', function()
          vim.diagnostic.jump({ count = 1, float = true })
        end, opts)
        vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
      end

      vim.lsp.config("*", {
        on_attach = on_attach,
        capabilities = capabilities,
      })
      -- lua_ls 的 vim 全局由 lazydev 提供，不再单独配 diagnostics.globals
      -- pyrefly（Rust 实现，替代 pyright）自己会向上找 .venv / venv / env 选解释器，
      -- 不需要像 pyright 那样手动把 pythonPath 塞进 settings。检查强度、
      -- include/exclude、search-path 写在项目根的 pyrefly.toml（或 pyproject.toml
      -- 的 [tool.pyrefly]）里；两者都没有时走 auto 配置，会先把近旁的
      -- pyrightconfig.json / mypy.ini 在内存里迁移过来，迁移不了才退到 basic 预设。
      -- 不设 workspace_required：没有标记时按单文件模式启动（root_dir 为空），
      -- pyrefly 本来就按文件自己找配置，实测无 root 时诊断、导入解析都正常；
      -- 设成 true 反而在无标记目录里不启动，比原来的 pyright 少了诊断。
      -- root_dir 为空的 buffer 共用一个客户端，不会每个文件起一个。
      vim.lsp.config("pyrefly", {
        -- 在上游默认（pyrefly.toml / pyproject.toml / setup.py / setup.cfg /
        -- requirements.txt / Pipfile / .git）基础上补 pyrightconfig.json —— 还没
        -- 迁到 pyrefly.toml 的项目靠它定位根；去掉 .git，否则 monorepo 根上只凭
        -- .git 就会把整棵树当成一个 workspace 索引一遍。
        root_markers = {
          "pyrefly.toml",
          "pyrightconfig.json",
          "pyproject.toml",
          "setup.py",
          "setup.cfg",
          "requirements.txt",
          "Pipfile",
        },
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
      -- pyrefly 不在这里：它由 uv tool 管理（~/.local/bin/pyrefly），让 mason 再装
      -- 一份会多出一个 python venv 和一条升级链路，容易分不清实际跑的是哪个二进制。
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "rust_analyzer", "ts_ls" },
        -- pyright 还留在 mason 里也别让它跟着 .py 启动，否则两套类型引擎同时挂在
        -- 同一个 buffer 上内存翻倍。在 automatic_enable 里排除，而不是等 setup
        -- 启用之后再 vim.lsp.enable("pyright", false)，后者依赖启用时序。
        automatic_enable = { exclude = { "pyright" } },
      })

      vim.lsp.enable("pyrefly")
    end,
  },
  {
    -- 编辑 nvim 配置本身时补 vim.* / luv 的类型与补全
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    -- 统一格式化入口；pyrefly 不做格式化，ruff/stylua/prettier 从这里走
    "stevearc/conform.nvim",
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" },
        desc = "Format",
      },
    },
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        -- rust 不配：lsp_format = "fallback" 走 rustfmt
      },
    },
  },
  {
    -- LSP 之外的静态检查；python 只用这里的 ruff，不再额外启用 ruff LSP
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      -- GUI 启动时 PATH 可能不含 conda 等目录；只注册当前找得到的 linter，
      -- 否则缺可执行文件会弹 "Error running ruff: ENOENT"。
      local wanted = {
        python = { "ruff" },
        sh = { "shellcheck" },
        dockerfile = { "hadolint" },
        yaml = { "yamllint" },
      }
      for ft, names in pairs(wanted) do
        lint.linters_by_ft[ft] = vim.tbl_filter(function(name)
          return vim.fn.executable(name) == 1
        end, names)
      end
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("UserLint", { clear = true }),
        callback = function() lint.try_lint() end,
      })
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      'nvim-lua/plenary.nvim',
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
      -- live_grep 的带参数版本：prompt 里可以直接写 rg 参数
      -- （"foo bar"、-tmd、--no-ignore、--iglob **/test/** …），固定 minor 版本避免破坏性更新。
      { 'nvim-telescope/telescope-live-grep-args.nvim', version = '^1.0.0' },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find Buffers" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      {
        "<leader>fG",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args()
        end,
        desc = "Live Grep (rg args)",
      },
    },
    config = function()
      local telescope = require("telescope")
      -- 只在 live_grep_args 的 picker 内生效，不影响其他 picker 的 <C-k>。
      -- 没绑 quote_prompt 时，prompt 不以 " ' - 开头会被整段当成一个参数。
      local lga_actions = require("telescope-live-grep-args.actions")
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
          live_grep_args = {
            auto_quoting = true,
            mappings = {
              i = {
                -- 覆盖 telescope 默认的 <C-k>（preview 右滚），换 rg 参数用的自动加引号
                ["<C-k>"] = lga_actions.quote_prompt(),
              },
            },
          },
        },
      })
      telescope.load_extension('fzf')
      telescope.load_extension('live_grep_args')
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
    opts = {
      sections = {
        lualine_x = {
          function() return vim.ui.progress_status() end,
          'encoding', 'fileformat', 'filetype',
        },
      },
    },
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
    -- diffview 自带一堆视图内键位（见 :h diffview-keymaps），但没有全局入口，
    -- 只能 :DiffviewOpen 之类手敲，这里补上 <leader>g*。
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview: Working Tree" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: File History" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: Current File History" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview: Close" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { winbar_info = true },
        file_history = { winbar_info = true },
      },
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
      -- 括号/引号自动配对；关掉 autopairs 自己的 <CR>，避免覆盖 cmp 的确认键
      { 'windwp/nvim-autopairs', opts = { map_cr = false } },
      'hrsh7th/cmp-nvim-lsp-signature-help',
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
          { name = 'nvim_lsp_signature_help', priority = 900 },
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

      -- autopairs 与 cmp 联动：确认补全后补上右半边括号
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

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
    dependencies = {
      { 'rcarriga/nvim-dap-ui', dependencies = { 'nvim-neotest/nvim-nio' }, opts = {} },
      { 'theHamsta/nvim-dap-virtual-text', opts = {} },
      -- codelldb（Rust/C/C++）自动安装并注册 adapter/configurations。
      -- Python 走 uv + dap-python，这里不声明 python。
      {
        'jay-babu/mason-nvim-dap.nvim',
        dependencies = { 'mason-org/mason.nvim' },
        opts = { ensure_installed = { 'codelldb' }, handlers = {} },
      },
    },
    keys = {
      { '<F5>', function() require('dap').continue() end, desc = "DAP: Continue" },
      { '<F10>', function() require('dap').step_over() end, desc = "DAP: Step Over" },
      { '<F11>', function() require('dap').step_into() end, desc = "DAP: Step Into" },
      { '<F12>', function() require('dap').step_out() end, desc = "DAP: Step Out" },
      { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = "DAP: Breakpoint" },
      { '<leader>du', function() require('dapui').toggle() end, desc = "DAP: UI" },
      { '<leader>dr', function() require('dap').repl.open() end, desc = "DAP: REPL" },
      { '<leader>dl', function() require('dap').run_last() end, desc = "DAP: Run Last" },
      { '<leader>dx', function() require('dap').terminate() end, desc = "DAP: Terminate" },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },
  {
    'mfussenegger/nvim-dap-python',
    ft = 'python',
    dependencies = { 'mfussenegger/nvim-dap' },
    keys = {
      { '<leader>dn', function() require('dap-python').test_method() end, desc = "Debug Test Method", ft = "python" },
      { '<leader>df', function() require('dap-python').test_class() end, desc = "Debug Test Class", ft = "python" },
    },
    config = function()
      -- debugpy 由 uv 临时环境提供，不依赖项目 venv
      require('dap-python').setup('uv')
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
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      -- visual 的 S 被 nvim-surround 占用，这里只绑 n/o
      { "S", mode = { "n", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash Remote" },
    },
  },
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (workspace)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (buffer)" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Loclist" },
    },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
    keys = {
      { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
      { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo (Telescope)" },
    },
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
  {
    "hong4rc/copy-path.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  }
})
