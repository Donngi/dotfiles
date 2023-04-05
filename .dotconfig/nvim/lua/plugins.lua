vim.cmd.packadd "packer.nvim"

require('packer').startup(function()
    use{ 'wbthomason/packer.nvim', opt = true}

    use {
        'nvim-tree/nvim-tree.lua',
        requires = {
          'nvim-tree/nvim-web-devicons',
        },
        config = function()
          require("nvim-tree").setup {}
        end
      }

    use {'neoclide/coc.nvim', branch='release'}

    use 'nvim-lua/plenary.nvim'
    use { 'nvim-telescope/telescope.nvim', tag = '0.1.1' }

    use 'Mofiqul/vscode.nvim'
end)
