---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach(client, bufnr)
  vim.diagnostic.config({
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
      -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
      -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
      -- prefix = "icons",
    },
    severity_sort = true,
  })

  local is_normal_buffer = vim.bo[bufnr].buftype == ""
  -- if client.supports_method("textDocument/inlayHint") and is_normal_buffer then
  --   vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  -- end

  if
    client:supports_method("textDocument/codeLens", bufnr) and is_normal_buffer
  then
    vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
      desc = "Refresh codelens",
      buffer = bufnr,
      callback = function()
        vim.lsp.codelens.refresh({ bufnr = 0 }) -- current buffer
      end,
    })
  end

  local keymap = vim.keymap.set

  keymap(
    "n",
    "gd",
    vim.lsp.buf.definition,
    { buffer = bufnr, desc = "Go to definition" }
  )
  keymap("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover" })
  keymap("n", "grn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename" })
  keymap(
    "n",
    "grr",
    "<cmd>Telescope lsp_references<CR>",
    { buffer = bufnr, desc = "Get references" }
  )
  keymap(
    "n",
    "gra",
    vim.lsp.buf.code_action,
    { buffer = bufnr, desc = "Code action" }
  )
  keymap(
    "i",
    "<C-s>",
    vim.lsp.buf.signature_help,
    { buffer = bufnr, desc = "Signature help" }
  )
  keymap("n", "[d", function()
    vim.diagnostic.jump({ count = -1 })
  end, { buffer = bufnr, desc = "Jump to previous diagnostic" })
  keymap("n", "]d", function()
    vim.diagnostic.jump({ count = 1 })
  end, { buffer = bufnr, desc = "Jump to next diagnostic" })
end

---@return lsp.ClientCapabilities
local function get_cmp_capabilities()
  local has_blink, blink = pcall(require, "blink.cmp")
  local has_cmp, cmp = pcall(require, "cmp_nvim_lsp")
  assert(
    not (has_blink and has_cmp),
    "can not have both blink-cmp and nvim-cmp at the same time"
  )

  if has_blink then
    return blink.get_lsp_capabilities()
  end

  if has_cmp then
    return cmp.default_capabilities()
  end

  return {}
end

local function get_capabilities()
  return vim.tbl_deep_extend(
    "force",
    {},
    vim.lsp.protocol.make_client_capabilities(),
    get_cmp_capabilities()
  )
end

---@type LazySpec
return {
  { "neovim/nvim-lspconfig", lazy = true },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    cmd = "LazyDev",
    version = "v1.9.0",
    opts = {
      library = {
        "lazy.nvim",
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    build = ":MasonUpdate",
    cmd = "Mason",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason.nvim",
      { "saghen/blink.cmp", optional = true },
      { "hrsh7th/nvim-cmp", optional = true },
    },
    opts = {

      automatic_enable = true,
      -- handlers = {
      --
      --   ["denols"] = function()
      --     local lspconfig = require("lspconfig")
      --     lspconfig.denols.setup({
      --       on_attach = on_attach,
      --       capabilities = get_capabilities(),
      --       root_dir = lspconfig.util.root_pattern("deno.json", "deno.cjson"),
      --       filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
      --     })
      --   end,
      --
      --   ["pyright"] = function()
      --     local lspconfig = require("lspconfig")
      --     lspconfig.pyright.setup({
      --       on_attach = on_attach,
      --       capabilities = get_capabilities(),
      --       settings = {
      --         python = {
      --           analysis = {
      --             typeCheckingMode = "basic",
      --           },
      --         },
      --       },
      --     })
      --   end,
      -- },
    },

    init = function()
      -- default config
      vim.lsp.config("*", {
        on_attach = on_attach,
        capabilities = get_capabilities(),
      })

      -- redefine filetypes
      vim.lsp.config.ts_ls = {
        filetypes = {
          "typescript",
          "typescriptreact",
          "typescript.tsx",
          "mdx",
          "javascript",
        },
      }

      vim.lsp.config.elixirls = {
        capabilities = {
          textDocument = {
            hover = {
              dynamicRegistration = true,
              contentFormat = { "markdown", "plaintext" },
            },
          },
        },
      }

      vim.lsp.config.lexical = {
        cmd = {
          vim.fn.expand("~/.local/share/nvim/mason/bin/lexical"),
          "server",
        },
        capabilities = vim.tbl_deep_extend("force", get_capabilities(), {
          textDocument = {
            hover = nil,
          },
        }),
      }

      vim.lsp.config.tailwindcss = {
        filetypes = {
          "typescript",
          "typescriptreact",
          "typescript.tsx",
          "astro",
          "javascript",
          "svelte",
        },
        settings = {
          tailwindCSS = {
            experimental = {
              classRegex = {
                { "tv\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
              },
            },
          },
        },
      }
    end,
  },
}
