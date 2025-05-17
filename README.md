# Neotypist

A simple Neovim plugin that tracks your typing speed in real-time.

![neotypistDemo](https://github.com/user-attachments/assets/cf79616e-e837-4b7f-a78f-2b106686f711)


## Overview

Neotypist displays your Words Per Minute (WPM) while you type in Neovim and provides encouraging notifications based on your typing speed. This is a learning project created to understand how Neovim plugins work.

## Features

- Real-time WPM tracking displayed as virtual text
- Customizable notifications for typing speed milestones
- Configurable thresholds and update intervals
- Lightweight with minimal impact on performance

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourusername/neotypist",
  opts = {
    -- your configuration options here
  }
}
```

## Configuration

Neotypist comes with sensible defaults but can be customized to your preferences:

```lua
require("neotypist").setup({
  -- Time in milliseconds between notifications (default: 60000)
  notify_interval = 60 * 1000,

  -- High WPM threshold for notification (default: 80)
  high = 80,

  -- Low WPM threshold for notification (default: 20)
  low = 20,

  -- Message to show when WPM is above high threshold
  high_message = "⚡️ You're a cheetah!",

  -- Message to show when WPM is below low threshold
  low_message = "🐢 Slowpoke!",

  -- Whether to show virtual text with WPM (default: true)
  show_virt_text = true,

  -- Whether to show notifications (default: true)
  notify = true,

  -- Time in milliseconds between WPM updates (default: 300)
  update_time = 300,

  -- Function that returns virtual text to display
  virt_text = function(wpm)
    return ("🚀 WPM: %.0f"):format(wpm)
  end,

  -- Position of virtual text (default: "right_align")
  virt_text_pos = "right_align",
})
```

## How It Works

Neotypist tracks your typing speed by:

1. Starting a timer when you enter insert mode
2. Counting the words typed since the timer started
3. Calculating your WPM based on elapsed time
4. Displaying the result as virtual text
5. Providing notifications based on your typing speed

## Contributing

This is a learning project created to understand how Neovim plugins work. Contributions are welcome and encouraged! Whether you're a beginner or experienced developer, feel free to:

- Report bugs
- Suggest new features
- Improve documentation
- Submit pull requests

No contribution is too small, and it's a great way to learn more about Neovim plugin development.

## License

MIT
