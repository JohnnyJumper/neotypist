local M = {}
local ns, stats = vim.api.nvim_create_namespace("Neotypist"), { start_words = 0, time = 0, timer = nil }
local last_notify_time = 0
local uv = vim.uv

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

M.setup()

return M
