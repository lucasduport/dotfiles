return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "github/copilot.vim",
    -- disable copilot by default
    lazy = true,
    keys = { "<leader>ce" },
    config = function()
      vim.cmd "Copilot setup"
      print "Copilot setup 🤖"
      vim.keymap.set("i", "<C-j>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
      })
      vim.keymap.set("n", "<leader>cd", function()
        vim.cmd ":Copilot disable"
        print "Copilot deactivated 🔥"
      end, {
        desc = "Disable Copilot",
      })
      vim.keymap.set("n", "<leader>ce", function()
        vim.cmd ":Copilot enable"
        print "Copilot enabled 🤖"
      end, {
        desc = "Enable Copilot",
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    lazy = true,
    event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
    config = function()
      local conform = require "conform"

      conform.setup {
        formatters_by_ft = {
          svelte = { "prettier" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          css = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          -- markdown = { "prettier" },
          lua = { "stylua" },
          python = { "isort", "black" },
          c = { "clang-format" },
        },
      }

      -- Config Black with line-length of 79
      conform.formatters.black = {
        prepend_args = { "--line-length", "79" },
      }

      vim.keymap.set({ "n", "v" }, "<leader>mp", function()
        conform.format {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        }
      end, { desc = "Format file or range (in visual mode)" })
    end,
  },
  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
