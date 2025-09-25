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

- You need patched font like NerdFont for icons to display.
- If you wish to use snippets (```snippets = true``` in config), than [luasnip](https://github.com/L3MON4D3/LuaSnip) is required
- For search to work `ripgrep` is required to be installed and [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for viewing the results. Other search types and pickers are planned to be added in future.


## Installation

### with Lazy.nvim

```lua
{
  "IKarasev/obsidian-tasks.nvim",
  dependencies = { 
      "L3MON4D3/LuaSnip", -- if using snippets
      "nvim-telescope/telescope.nvim", -- if want to search to work
  },
  lazy = true,
  ft = "markdown",
  config = function()
    require("obsidian-tasks").setup() -- uses default config if no options provided
  end,
}
```

### with Packer.nvim

```lua
use {
  "IKarasev/obsidian-tasks.nvim",
  requires = { 
      "L3MON4D3/LuaSnip", -- if using snippets
      "nvim-telescope/telescope.nvim", -- if want to search to work
  }
  ft = {'markdown'},
  config = function()
    require("obsidian-tasks").setup() -- uses default config if no options provided
  end,
}
```

## Usage

### :zap: Snippets

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

### :pencil2: Compliting and canceling tasks

Plugin creates two user commands:
- `ObTaskComplete` - complites task on current line in buffer; if recurent task, then can replace it with new, or add new depending on chosen option in config (`config.recurOnComplite`)
- `ObTaskCancel` - cancels task on current line in buffer

Which can be mapped to a key with `vim.keymap.set()` after plugin setup:

```lua
vim.keymap.set("n", "<leader>td", ":ObTaskComplete")
vim.keymap.set("n", "<leader>tc", ":ObTaskCancel")
```

### :mag_right: Search

Tasks search can be disabled in config: `config.search = false`

To perform search, the user command us used in next format:

```
ObTaskFind ?status ?period ?start ?end
```

Command argumetns:
| Arg | Values | Default | Description |
| --------------- | ------ | --------------- | --------------- |
| status | all, todo, done, canceled, in_progress, active, missed | all | task status to search<br>- active - todo tasks from today<br>- missed - todo tasks till today |
| period | day, week, month | day | time period to filter tasks, if status is `missed` - searches tasks in past |
| start | integer | | number of periods from today, if `end` is not set - searchers from today to this number of period |
| end | integer | | if set, searches tasks from `today+start` till `today+end` periods |

All argumetns are optional, if not options given, than lists all tasks. Results displayed in picker (telescope for now).

#### Examples

| Command | Description |
| -------------- | --------------- |
| `ObTaskFind` | lists all tasks |
| `ObTaskFind todo` | lists all todo tasks |
| `ObTaskFind todo month` | lists todo tasks for next 30 days |
| `ObTaskFind canceled month -3` | lists canceled tasks for last 90 days |
| `ObTaskFind missed day 5` | lists missed task for last 5 days|
| `ObTaskFind todo week 1 3` | lists todo tasks from today+7 day till today+21 day |


## Configuration

Full list of options with default values:

```lua
{
    dateFormat = "%Y-%m-%d", -- date format to use 
	taskTag = "#task",       -- tag to use for task identification 
	snippets = true,         -- load snippets or not
    search = true,           -- activate seach command
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
	userCmd = {              
        -- names for plugin user commands
		enabled = true,                  -- enable user commands
		taskComplete = "ObTaskComplete", -- name for comliting task cmd
		taskCancel = "ObTaskCancel",     -- name for canceling task cmd
		taskFind = "ObTaskFind",         -- name for search cmd
	},
    -- set empty to just mark task complited
    -- action for recur task complition
    -- values: "replace", "add_after", "add_before"
	recurOnComplite = "replace", 
	hl = {                       
        -- highlight groups
		ObTaskSnipHint = { fg = "#737aa2", italic = true },
	},
}
```

