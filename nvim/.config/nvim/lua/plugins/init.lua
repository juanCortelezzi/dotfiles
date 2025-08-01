return {
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    ---@module "ibl"
    ---@type ibl.config
    opts = {},
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "catgoose/nvim-colorizer.lua",
    opts = {
      user_default_options = {
        css = true,
        tailwind = true,
      },
    },
    keys = {
      {
        "<leader>bca",
        function()
          require("colorizer").attach_to_buffer()
        end,
        desc = "Attach Colorizer to Buffer",
      },
      {
        "<leader>bcd",
        function()
          require("colorizer").detach_from_buffer()
        end,
        desc = "Detach Colorizer to Buffer",
      },
    },
  },
  {
    "dstein64/vim-startuptime",
    cmd = "StartupTime",
    init = function()
      vim.g.startuptime_tries = 10
    end,
  },
}
