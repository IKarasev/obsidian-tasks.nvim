# obsidian-tasks.nvim

I use [obsidian.md](https://obsidian.md/) with [tasks](https://publish.obsidian.md/tasks/Introduction),
and I use [obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim) to work with my notes in Neovim.

Unfortunatly, the neovim plugin doesn't work with obsidian tasks. So I tried my best to implement some of it
functionality inside neovim. For now this plugin can:
- create tasks using snippets
- complete and cancel tasks with appropriate formating
- limitted support for recuring tasks:
    - parses recurence strings
    - calculates next date (with "when done" support)
    - can replace current recur task with new or add it befor\after the complited one
    - <span style="color:red">🗙</span> repeating months, weekdays and dates are not yet supported (e.g. *every January, Febrary on the 1nd and 3rd*)

This plugin does not depend on obsidian.nvim and works directly with markdown files, so it can be used outside of Obsidian vaults if you wish.

## Dependencies

For now only one dependency exists if you wish to use snippets:
- [LuaSnip](https://github.com/L3MON4D3/LuaSnip)

## Instalation


## Dependencies

For now, only one dependency exists if you wish to use snippets:
- [luasnip](https://github.com/L3MON4D3/LuaSnip)

## Installation

### with Lazy.nvim

```lua

```

## Configuration

Full list of options with default values:

```lua
{
    dateFormat = "%Y-%m-%d", -- date format to use 
	taskTag = "#task",       -- tag to use for task identification 
	snippets = true,         -- load snippets or not
	taskIcon = {             
        -- icons used for task line parts
		due = "⏳",
		scheduled = "📅",
		start = "🛫",
		recur = "🔁",
		created = "➕",
		complited = "✅",
		canceled = "❌",
	},
	taskMark = {             
        -- used to set task status
		todo = " ",
		done = "x",
		canceled = "-",
		inprogress = "/",
		nontask = "~",
	},
	userCmd = {              
        -- names for plugin user commands
		enabled = true,
		taskComplete = "ObTaskComplete",
		taskCancel = "ObTaskCancel",
	},
	recurOnComplite = "replace", -- action for recur task complition
                                 -- "replace", "add_after", "add_before"
                                 -- set empty to just mark task complited

	hl = {                       
        -- highlight groups
		ObTaskSnipHint = { fg = "#737aa2", italic = true },
	},
	dateOpts = {  
        -- options for date string parsing
        -- automaticly updates if non default date format set
        -- if changed, the new values will be used
		pat = "(%d%d%d%d)%-(%d%d)%-(%d%d)",
		order = {
			Y = 1,
			m = 2,
			d = 3,
		},
	},
}

```
