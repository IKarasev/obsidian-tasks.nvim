# obsidian-tasks.nvim

I use [obsidian.md](https://obsidian.md/) with [tasks](https://publish.obsidian.md/tasks/Introduction) plugin,
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

You need patched font like NerdFont for icons to display.

As for plugin dependencies, only one dependency needed only if you wish to use snippets:
- [LuaSnip](https://github.com/L3MON4D3/LuaSnip)

## Dependencies

For now, only one dependency exists if you wish to use snippets:
- [luasnip](https://github.com/L3MON4D3/LuaSnip)

## Installation

### with Lazy.nvim

```lua
{
  "IKarasev/obsidian-tasks.nvim",
  dependencies = { "L3MON4D3/LuaSnip" }, -- if using snippets
  lazy = true,
  ft = "markdown",
  config = function()
    require("obsidian-tasks").setup()
  end,
}
```

### with Packer.nvim

```lua
use {
  "IKarasev/obsidian-tasks.nvim",
  requires = { "L3MON4D3/LuaSnip" }, -- if using snippets
  ft = {'markdown'},
  config = function()
    require("obsidian-tasks").setup()
  end,
}
```

## Usage

### Snippets

Plugin creates three snippets:
- `task_schedule` creates scheduled task:
```md
- [ ] #task Do something on 📅 2025-08-12
```
- `task_due` creates due task:
```md
- [ ] #task Do something due ⏳ 2025-08-20
```
- `task_recur` creates recuring task:
```md
- [ ] #task Do every month 🔁 every month 🛫 2025-08-13
```

### Compliting and canceling tasks

Plugin creates two user commands:
- `ObTaskComplete` - complites task on current line in buffer
- `ObTaskCancel` - cancels task on current line in buffer

Which can be mapped to a key with `vim.keymap.set()` after plugin setup:

```lua
vim.keymap.set("n", "<leader>td", ":ObTaskComplete")
vim.keymap.set("n", "<leader>tc", ":ObTaskCancel")
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
    -- set empty to just mark task complited
    -- action for recur task complition
    -- values: "replace", "add_after", "add_before"
	recurOnComplite = "replace", 
	hl = {                       
        -- highlight groups
		ObTaskSnipHint = { fg = "#737aa2", italic = true },
	},
	dateOpts = {  
        -- options for date string parsing
        -- automaticly updates if non default date format set
        -- if changed, these values will be used

        -- pattern to use in date search
		pat = "(%d%d%d%d)%-(%d%d)%-(%d%d)",
        -- order of year, month and day in pattern
		order = {
			Y = 1,
			m = 2,
			d = 3,
		},
	},
}
```

