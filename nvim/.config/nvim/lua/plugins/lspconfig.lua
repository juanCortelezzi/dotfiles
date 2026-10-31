---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach(client, bufnr)
  if
    client:supports_method("textDocument/codeLens", bufnr)
    and vim.bo[bufnr].buftype == ""
  then
    vim.lsp.codelens.enable(true, { bufnr = bufnr })
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
  {
    "neovim/nvim-lspconfig",
    lazy = true,
    config = function()
      vim.lsp.enable("ocamllsp")
    end,
  },
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
    lazy = false,
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "mason-org/mason.nvim",
      { "saghen/blink.cmp", optional = true },
      { "hrsh7th/nvim-cmp", optional = true },
    },
    opts = {
      automatic_enable = true,
    },

    init = function()
      vim.diagnostic.config({
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        severity_sort = true,
      })

      -- default config
      vim.lsp.config("*", {
        capabilities = get_capabilities(),
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user.lsp", { clear = true }),
        callback = function(event)
          local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
          on_attach(client, event.buf)
        end,
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
