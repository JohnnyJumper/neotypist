---@class Neotypist
local M = {}

local ns = vim.api.nvim_create_namespace("Neotypist")

---@class NeotypistStats
---@field start_words number Number of words when timer started.
---@field time number Start time in milliseconds.
---@field timer? uv.uv_timer_t Timer object from vim.uv.

---@type NeotypistStats
local stats = { start_words = 0, time = 0, timer = nil }
local last_notify_time = 0
local uv = vim.uv

---@class NeotypistOptions
---@field notify_interval number Time in milliseconds between notifications (default: 60000).
---@field high number High WPM threshold for notification (default: 80).
---@field low number Low WPM threshold for notification (default: 20).
---@field high_message string Message to show when WPM is above high threshold (default: "⚡️ You're a cheetah!").
---@field low_message string Message to show when WPM is below low threshold (default: "🐢 Slowpoke!").
---@field show_virt_text boolean Whether to show virtual text with WPM (default: true).
---@field notify boolean Whether to show notifications (default: true).
---@field update_time number Time in milliseconds between WPM updates (default: 300).
---@field virt_text fun(wpm: number): string Function that returns virtual text to display (default: "🚀 WPM: {wpm}").
---@field virt_text_pos string Position of virtual text (default: "right_align").

---@type NeotypistOptions
local options = {
	notify_interval = 60 * 1000, -- one minute
	high = 80,
	low = 20,
	high_message = "⚡️ You’re a cheetah!",
	low_message = "🐢 Slowpoke!",
	show_virt_text = true,
	notify = true,
	update_time = 300,
	virt_text = function(wpm)
		return ("🚀 WPM: %.0f"):format(wpm)
	end,
	virt_text_pos = "right_align",
}

---@param opts? NeotypistOptions
local function overrideOptions(opts)
	opts = opts or {}
	options.notify_interval = opts.notify_interval or options.notify_interval
	options.high = opts.high or options.high
	options.low = opts.low or options.low
	options.high_message = opts.high_message or options.high_message
	options.low_message = opts.low_message or options.low_message
	options.show_virt_text = opts.show_virt_text or options.show_virt_text
	options.notify = opts.notify or options.notify
	options.update_time = opts.update_time or options.update_time
	options.virt_text = opts.virt_text or options.virt_text
	options.virt_text_pos = opts.virt_text_pos or options.virt_text_pos
end

---@param wpm number Words per minute
local function maybeNotify(wpm)
	local now = uv.now()
	if last_notify_time == 0 then
		last_notify_time = now
		return
	end
	if now - last_notify_time < options.notify_interval then
		return
	end
	if wpm > options.high then
		vim.notify(options.high_message, vim.log.levels.INFO)
		last_notify_time = now
	end
	if wpm < options.low then
		vim.notify(options.low_message, vim.log.levels.WARN)
		last_notify_time = now
	end
end

---@param wpm number Words per minute
local function render(wpm)
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	vim.api.nvim_buf_set_extmark(0, ns, 0, 0, {
		virt_text = { { options.virt_text(wpm), "Comment" } },
		virt_text_pos = options.virt_text_pos,
	})
	if options.notify then
		maybeNotify(wpm)
	end
end

local function tick()
	local now = uv.now()
	local dt = (now - stats.time) / 1000

	if dt <= 0 then
		return
	end

	local words = vim.fn.wordcount().words
	local typed = words - stats.start_words
	local wpm = typed / (dt / 60)

	if options.show_virt_text then
		render(wpm)
	end
end

local function start_timer()
	if stats.timer then
		return
	end
	stats.timer = uv.new_timer()
	stats.time = uv.now()
	stats.start_words = vim.fn.wordcount().words
	stats.timer:start(0, options.update_time, vim.schedule_wrap(tick))
end

local function stop_timer()
	if stats.timer then
		stats.timer:stop()
		stats.timer:close()
		stats.timer = nil
	end
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

---@param opts? NeotypistOptions
function M.setup(opts)
	overrideOptions(opts)
	local group = vim.api.nvim_create_augroup("Neotypist", { clear = true })
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = group,
		callback = start_timer,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		group = group,
		callback = stop_timer,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = stop_timer,
	})
end

---@return Neotypist
return M
