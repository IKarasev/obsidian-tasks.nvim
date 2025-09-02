local config = require("obsidian-tasks.config").getConfig()
local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.s
local i = ls.insert_node
local c = ls.choice_node
local t = ls.text_node

local M = {}

local cur_date = function()
	return os.date(config.dateFormat)
end

local ext_opts = {
	desc = {
		active = {
			virt_text = { { "← description", "ObTaskSnipHint" } },
		},
		unvisited = {
			hl_group = "NvimColon",
		},
	},
	cur_date = {
		active = {
			virt_text = { { "← cur date?", "ObTaskSnipHint" } },
		},
	},
	target_date = {
		active = {
			virt_text = { { "← target date", "ObTaskSnipHint" } },
		},
		unvisited = {
			hl_group = "NvimColon",
		},
	},
	recur_date_type = {
		active = {
			virt_text = { { "← recur target type", "ObTaskSnipHint" } },
		},
	},
	recur_period = {
		active = {
			virt_text = { { "← recur period", "ObTaskSnipHint" } },
			hl_group = "LspReferenceText",
		},
		unvisited = {
			hl_group = "NvimColon",
		},
	},
}

local getSnippets = function()
	return {
		s(
			"task_due",
			fmt("- [ ] #task {desc}{created} " .. config.taskIcon.due .. " {date}", {
				desc = i(1, { "desc" }, { node_ext_opts = ext_opts.desc }),
				created = c(2, { t(""), t(" ➕ " .. cur_date()) }, { node_ext_opts = ext_opts.cur_date }),
				date = i(3, { cur_date() }, { node_ext_opts = ext_opts.target_date }),
			})
		),
		s(
			"task_schedule",
			fmt("- [ ] #task {desc}{created} " .. config.taskIcon.scheduled .. " {date}", {
				desc = i(1, { "desc" }, { node_ext_opts = ext_opts.desc }),
				created = c(
					2,
					{ t(""), t(" " .. config.taskIcon.created .. " " .. cur_date()) },
					{ node_ext_opts = ext_opts.cur_date }
				),
				date = i(3, { cur_date() }, { node_ext_opts = ext_opts.target_date }),
			})
		),
		s(
			"task_recur",

			fmt("- [ ] #task {desc} " .. config.taskIcon.recur .. " every {period}{created} {sttype} {date}", {
				desc = i(1, { "desc" }, { node_ext_opts = ext_opts.desc }),
				period = c(
					2,
					{ t("days"), t("week"), t("month"), t("year") },
					{ node_ext_opts = ext_opts.recur_period }
				),
				created = c(
					3,
					{ t(""), t(" " .. config.taskIcon.created .. " " .. cur_date()) },
					{ node_ext_opts = ext_opts.cur_date }
				),
				sttype = c(
					4,
					{ t(config.taskIcon.start), t(config.taskIcon.scheduled), t(config.taskIcon.due) },
					{ node_ext_opts = ext_opts.recur_date_type }
				),
				date = i(5, { cur_date() }, { node_ext_opts = ext_opts.target_date }),
			})
		),
	}
end

M.add_snippets = function()
	ls.add_snippets("markdown", getSnippets())
end

return M
