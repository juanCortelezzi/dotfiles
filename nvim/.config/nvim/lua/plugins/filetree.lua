---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-tree/nvim-web-devicons", optional = true },
    "MunifTanjim/nui.nvim",
  },
  opts = {
    window = {
      position = "right",
      same_level = true, -- Create and paste/move files/directories on the same level as the directory under cursor (as opposed to within the directory under cursor).
      -- Affects how nodes get inserted into the tree during creation/pasting/moving of files if the node under the cursor is a directory:
      -- "child":   Insert nodes as children of the directory under cursor.
      -- "sibling": Insert nodes  as siblings of the directory under cursor.
      insert_as = "child",
      mappings = {
        ["<C-v>"] = "open_vsplit",
        ["<C-h>"] = "open_split",
      },
    },
    enable_git_status = false,
    enable_diagnostics = false,
  },
  keys = {
    {
      "<leader><leader>",
      ":Neotree toggle reveal<CR>",
      { desc = "Open neo-tree at current file or working directory" },
    },
  },
}
