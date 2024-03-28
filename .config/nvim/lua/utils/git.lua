local M = {}

function M.commitStagedFiles()
	local message = vim.fn.input("Enter commit message: ")

	if message ~= "" then
		vim.fn.system('git commit -m "' .. message .. '"')
	else
		print("Commit message cannot be empty!")
	end
end

return M
