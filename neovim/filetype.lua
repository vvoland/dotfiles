vim.filetype.add({
	extension = {
		dpk = "pascal",
	},
	pattern = {
		[".*/%.github/workflows/.*%.ya?ml"] = "yaml.gha",
	},
})
