---@type LazySpec
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = function()
    local opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "isort", "black" },
        go = { "gofmt" },
        templ = { "gofmt" },
        rust = { "rustfmt" },
        bash = { "shfmt" },
        zig = { "zigfmt" },
        ocaml = { "ocamlformat" },
        terraform = { "terraform" },
      },
      default_format_opts = {
        timeout_ms = 3000,
        async = false, -- not recommended to change
        quiet = false, -- not recommended to change
        lsp_format = "fallback", -- not recommended to change
      },

      -- enable format on save
      format_on_save = {},
      formatters = {
        -- LazyVim has this so I have to have it too.
        injected = { options = { ignore_errors = true } },
        shfmt = {
          prepend_args = { "-i", "2" },
        },
      },
    }

    local shitty_fts = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "astro",
      "svelte",
      "vue",
      "toml",
      "html",
      "css",
      "scss",
      "markdown",
      "mdx",
      "json",
      "jsonc",
      "yaml",
    }

    for _, ft in ipairs(shitty_fts) do
      opts.formatters_by_ft[ft] = {
        "prettier",
        "biome",
        stop_after_first = true,
      }
    end

    return opts
  end,
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
  keys = {
    {
      "<leader>bf",
      function()
        require("conform").format({ async = false, timeout_ms = 3000 })
      end,
      mode = "n",
      desc = "Format buffer",
    },
  },
}
