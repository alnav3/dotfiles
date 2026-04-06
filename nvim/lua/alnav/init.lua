-- Load Nix-managed Treesitter grammars (preinstalled via NixOS)
local treesitter_config = "/etc/xdg/nvim/treesitter-nix.lua"
if vim.fn.filereadable(treesitter_config) == 1 then
  dofile(treesitter_config)
end

require("alnav.remap")
require("alnav.set")
require("alnav.packer")
require("alnav.java")


