return {
	"f-person/git-blame.nvim",
	event = "VeryLazy",
	opts = {
		enabled = true,
		message_template = "<author> • <summary> • <date>",
		date_format = "%m-%d-%Y %H:%M:%S",
		virtual_text_column = 1,
	},
}
