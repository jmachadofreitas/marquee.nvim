if vim.g.loaded_marquis == 1 then return end

vim.g.loaded_marquis = 1

vim.api.nvim_set_hl(0, 'MarkSignHL', { default = true, link = 'DiagnosticHint' })
vim.api.nvim_set_hl(0, 'MarkSignNumHL', { default = true, link = 'MarkSignHL' })
