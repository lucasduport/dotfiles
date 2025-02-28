local configs = require "nvchad.configs.lspconfig"

local servers = {
  html = {},
  awk_ls = {},
  bashls = {},
  ts_ls = {},
  cssls = {},
  tailwindcss = {},
  lua_ls = {},
  emmet_ls = {},
  pyright = {},
  clangd = {
    init_options = {
      fallbackFlags = { "--std=c++20" },
    },
  },
}

for name, opts in pairs(servers) do
  opts.on_init = configs.on_init
  opts.on_attach = configs.on_attach
  opts.capabilities = configs.capabilities

  require("lspconfig")[name].setup(opts)
end
