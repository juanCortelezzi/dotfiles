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
  keymap("n", "K", function()
    vim.lsp.buf.hover({
      max_width = math.max(math.floor(vim.o.columns * 0.4), 60),
      border = "rounded",
    })
  end, {
    buffer = bufnr,
    desc = "Hover",
  })
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

      vim.lsp.config.nextls = {
        cmd = { "nextls", "--stdio" },
        init_options = {
          extensions = {
            credo = { enable = true },
          },
          experimental = {
            completions = { enable = true },
          },
        },
        root_markers = { "mix.exs", ".git" },
      }

      -- vim.lsp.config.elixirls = {
      --   capabilities = {
      --     textDocument = {
      --       hover = {
      --         dynamicRegistration = true,
      --         contentFormat = { "markdown", "plaintext" },
      --       },
      --     },
      --   },
      -- }

      -- vim.lsp.config.lexical = {
      --   cmd = {
      --     vim.fn.expand("~/.local/share/nvim/mason/bin/lexical"),
      --     "server",
      --   },
      --   cmd_cwd = vim.fn.expand("~/.local/share/nvim/mason/packages/lexical"),
      --   capabilities = vim.tbl_deep_extend("force", get_capabilities(), {
      --     textDocument = {
      --       hover = nil,
      --     },
      --   }),
      -- }

      vim.lsp.config.tailwindcss = {
        filetypes = {
          "typescript",
          "typescriptreact",
          "typescript.tsx",
          "astro",
          "javascript",
          "svelte",
          "elixir",
          "heex",
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

      vim.lsp.config.jdtls = {

        ---@param dispatchers? vim.lsp.rpc.Dispatchers
        ---@param config vim.lsp.ClientConfig
        cmd = function(dispatchers, config)
          local cache_dir = vim.fn.stdpath("cache")
          local data_dir = vim.fs.joinpath(cache_dir, "/jdtls/workspace")
          if config.root_dir then
            local project_name = vim.fn.fnamemodify(config.root_dir, ":p:h:t")
            data_dir = vim.fs.joinpath(data_dir, project_name)
          end

          local lombok_jar = vim.fn.expand("$MASON/share/jdtls/lombok.jar")

          local config_cmd = {
            "jdtls",
            "-data",
            data_dir,
            string.format("--jvm-arg=-javaagent:%s", lombok_jar),
          }

          return vim.lsp.rpc.start(config_cmd, dispatchers, {
            cwd = config.cmd_cwd,
            env = config.cmd_env,
            detached = config.detached,
          })
        end,
        settings = {
          java = {
            configuration = {
              -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
              -- And search for `interface RuntimeOption`
              -- The `name` is NOT arbitrary, but must match one of the elements from `enum ExecutionEnvironment` in the link above
              runtimes = {
                {
                  name = "JavaSE-21",
                  path = vim.fs.joinpath(
                    vim.env.SDKMAN_DIR,
                    "candidates/java/21.0.9-tem/"
                  ),
                },
                {
                  name = "JavaSE-25",
                  path = vim.fs.joinpath(
                    vim.env.SDKMAN_DIR,
                    "candidates/java/25.0.1-tem/"
                  ),
                },
              },
            },
          },
        },
      }
    end,
  },
}
