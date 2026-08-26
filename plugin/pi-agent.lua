if vim.g.loaded_pi_agent == 1 then
  return
end

vim.g.loaded_pi_agent = 1
require("pi_agent").setup()
