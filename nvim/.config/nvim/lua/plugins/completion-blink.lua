---@type LazySpec
return {
  {
    "saghen/blink.cmp",
    version = "v0.10.0",
    enabled = true,
    dependencies = {
      "rafamadriz/friendly-snippets",
      {
        "folke/lazydev.nvim",
        optional = true,
      },
      {
        "saghen/blink.compat",
        opts = {},
        optional = true,
        version = "*",
      },
    },
    opts_extend = { "sources.default" },
    opts = {
      -- signature = { enabled = true },
      completion = {
        menu = {
          border = "rounded",
        },
        documentation = {
          window = {
            border = "rounded",
          },
        },
      },
      sources = {
        default = {
          "lazydev",
          "lsp",
          "path",
          "snippets",
          "buffer",
        },
        providers = {
          buffer = {
            min_keyword_length = 5,
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
    },
    config = function(_, opts)
      -- setup compat sources
      local enabled = opts.sources.default
      for _, source in ipairs(opts.sources.compat or {}) do
        opts.sources.providers[source] = vim.tbl_deep_extend(
          "force",
          { name = source, module = "blink.compat.source" },
          opts.sources.providers[source] or {}
        )
        if
          type(enabled) == "table" and not vim.tbl_contains(enabled, source)
        then
          table.insert(enabled, source)
        end
      end

      -- check if we need to override symbol kinds
      for _, provider in pairs(opts.sources.providers or {}) do
        if provider.kind then
          require("blink.cmp.types").CompletionItemKind[provider.kind] =
            provider.kind
          local transform_items = provider.transform_items
          provider.transform_items = function(ctx, items)
            items = transform_items and transform_items(ctx, items) or items
            for _, item in ipairs(items) do
              item.kind = provider.kind or item.kind
            end
            return items
          end
        end
      end

      require("blink.cmp").setup(opts)
    end,
  },
}
