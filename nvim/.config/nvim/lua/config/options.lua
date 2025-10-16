local opt = vim.opt

opt.confirm = true -- Confirm to save changes before closing modified buffer.
opt.wrap = false
opt.number = true
opt.relativenumber = true
opt.clipboard = "unnamedplus" -- Use system clipboard
opt.splitright = true -- New window is put rigt of the current one.
opt.splitbelow = true -- New window from split is belaw the current one.
opt.mouse = "a" -- Enable mouse mode
opt.pumblend = 10 -- Enable popup pseudo-transparency
opt.pumheight = 10 -- Max number of entries in a popup
opt.smartindent = true
opt.termguicolors = true -- Enable true color support
opt.timeoutlen = 300 -- Timeout for keymaps
opt.undofile = true
opt.undolevels = 10000
opt.winminwidth = 5 -- Minimum width for windows
opt.swapfile = false -- Write flie straight to disk instead of breaking hot reloading

opt.list = true -- Shows hidden characters (whitespace and stuff...)
opt.listchars = {
  tab = "│ ",
  extends = "",
  precedes = "",
  trail = "",
}

-- Set cursorline
opt.cursorline = true -- Enable highlighting of the current line.
opt.scrolloff = 4 -- Padding between top/bottom of the screen and cursorline
opt.sidescrolloff = 4 -- Padding between left/right of the screen and cursorline

-- Set bottom UI
opt.laststatus = 3
opt.showmode = false -- Do not show mode in message line since we have a statusline
opt.splitkeep = "screen"
opt.shortmess:append({ -- Message line settings
  W = true,
  I = true,
  c = true,
  C = true,
})

-- Set spacing
opt.shiftwidth = 2
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftround = true -- Round < and > to shiftwidth
opt.expandtab = true -- Use spaces instead of tabs.

-- Set ripgrep
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"

-- Set search
opt.ignorecase = true
opt.smartcase = true

-- Not sure what this is but LazyVim has it...
opt.inccommand = "nosplit"
-- opt.updatetime = 200 -- Save to disk after timeout of no writing
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize" }
opt.formatoptions = "jcroqlnt" -- tcqj
