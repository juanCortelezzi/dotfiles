return {
  "ibhagwan/fzf-lua",
  -- optional for icon support
  dependencies = { "nvim-tree/nvim-web-devicons" },
  -- or if using mini.icons/mini.nvim
  -- dependencies = { "nvim-mini/mini.icons" },
  ---@module "fzf-lua"
  ---@type fzf-lua.Config|{}
  ---@diagnostic disable: missing-fields
  opts = {"telescope"},
  ---@diagnostic enable: missing-fields
  keys = {
    {
      "<leader>f",
      function()
        require("fzf-lua").files()
      end,
      desc = "Telescope find files",
    },
  }
}
