local live_multigrep = function(opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local make_entry = require("telescope.make_entry")
  local conf = require("telescope.config").values
  local job = require("plenary.job")

  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  local get_fd_pahts_sync = function(pattern)
    local fd_job = job:new({
      command = "fd",
      args = { "-c=never", pattern },
      cwd = opts.cwd,
      enable_recording = true,
    })

    local fd_paths, fd_status_code = fd_job:sync()
    if fd_status_code > 0 then
      local err = fd_job:stderr_result()
      local err_string = ""
      for index, line in ipairs(err) do
        if index ~= 1 then
          err_string = err_string .. " "
        end
        err_string = err_string .. line
      end
      error(err_string)
    end

    return fd_paths or {}
  end

  local command_generator = function(prompt)
    if not prompt or prompt == "" then
      return nil
    end

    local pieces = vim.split(prompt, "  ")
    local rg_pattern = pieces[1]
    local fd_pattern = pieces[2]

    local args = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
    }
    if rg_pattern and rg_pattern ~= "" then
      table.insert(args, "-e")
      table.insert(args, rg_pattern)
    end

    if fd_pattern and fd_pattern ~= "" then
      local fd_paths = get_fd_pahts_sync(fd_pattern)
      for _, path in ipairs(fd_paths) do
        table.insert(args, path)
      end
    end

    return args
  end

  local finder = finders.new_async_job({
    command_generator = command_generator,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  })

  pickers
    .new(opts, {
      debounce = 150,
      prompt_title = "Multi Grep",
      finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = require("telescope.sorters").empty(),
    })
    :find()
end

---@type LazySpec
return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-tree/nvim-web-devicons", optional = true },
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  opts = {
    defaults = {
      mappings = {
        i = {
          ["<c-t>"] = function(bufnr, opts)
            require("trouble.sources.telescope").open(bufnr, opts)
          end,
        },
        n = {
          ["<c-t>"] = function(bufnr, opts)
            require("trouble.sources.telescope").open(bufnr, opts)
          end,
        },
      },
    },
    extensions = {
      fzf = {},
    },
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    telescope.load_extension("fzf")
  end,
  keys = {
    {
      "<leader>f",
      function()
        require("telescope.builtin").find_files()
      end,
      desc = "Telescope find files",
    },
    {
      "<leader>g",
      function()
        live_multigrep()
      end,
      desc = "Telescope live grep",
    },
    {
      "<leader>h",
      function()
        require("telescope.builtin").help_tags()
      end,
      desc = "Telescope help tags",
    },
    {
      "<leader>tt",
      function()
        require("telescope.builtin").builtin()
      end,
      desc = "Telescope builtins",
    },
    {
      "<leader>en",
      function()
        require("telescope.builtin").find_files({
          cwd = vim.fn.stdpath("config"),
        })
      end,
      desc = "Telescope edit neovim files",
    },
  },
}
