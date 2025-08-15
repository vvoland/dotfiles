-- lua/ai.lua
local M = {}

-- How many lines of context to include around the selection (not modified).
local CONTEXT_BEFORE = 150
local CONTEXT_AFTER = 150

-- Figure out the exact byte-range of the visual selection (exclusive end).
local function get_visual_range()
	-- 1-based rows, 0-based cols (byte indices)
	local srow, scol = table.unpack(vim.api.nvim_buf_get_mark(0, "<"))
	local erow, ecol = table.unpack(vim.api.nvim_buf_get_mark(0, ">"))

	-- If marks aren't set (not a visual command), bail.
	if srow == 0 or erow == 0 then
		return nil, "Run :Gpt from visual selection (or with :'<,'>Gpt ...)."
	end

	-- Normalize
	if srow > erow or (srow == erow and scol > ecol) then
		srow, erow = erow, srow
		scol, ecol = ecol, scol
	end

	-- Detect selection type (best-effort even after leaving Visual):
	local vtype = vim.fn.getregtype():sub(1, 1) -- 'v', 'V', or Ctrl-V (block)
	if vtype == "\022" then
		return nil, "Blockwise visual selection not supported."
	end

	-- Linewise: '> col is huge (INT_MAX). Make it full lines.
	local is_linewise = (vtype == "V") or (ecol >= 2147483646)

	if is_linewise then
		local last_line = (vim.api.nvim_buf_get_lines(0, erow - 1, erow, false)[1] or "")
		return { srow = srow, scol = 0, erow = erow, ecol_ex = #last_line }, nil
	end

	-- Characterwise: clamp end to line length and convert to exclusive
	local last_line = (vim.api.nvim_buf_get_lines(0, erow - 1, erow, false)[1] or "")
	local line_len = #last_line
	local ecol_ex = math.min(ecol + 1, line_len) -- exclusive end
	local first_line = (vim.api.nvim_buf_get_lines(0, srow - 1, srow, false)[1] or "")
	local scol_cl = math.min(scol, #first_line)

	return { srow = srow, scol = scol_cl, erow = erow, ecol_ex = ecol_ex }, nil
end

local function get_visual_text(range)
	if not range then return "" end
	local lines = vim.api.nvim_buf_get_lines(0, range.srow - 1, range.erow, false)
	if #lines == 0 then return "" end

	if range.srow == range.erow then
		lines[1] = string.sub(lines[1], range.scol + 1, range.ecol_ex)
	else
		lines[1] = string.sub(lines[1], range.scol + 1)
		lines[#lines] = string.sub(lines[#lines], 1, range.ecol_ex)
	end

	return table.concat(lines, "\n")
end

local function get_context_lines(range, before, after)
	local total = vim.api.nvim_buf_line_count(0)
	local before_start = math.max(1, range.srow - before)
	local before_end = range.srow - 1
	local after_start = range.erow + 1
	local after_end = math.min(total, range.erow + after)

	local before_lines = {}
	local after_lines = {}

	if before_end >= before_start then
		before_lines = vim.api.nvim_buf_get_lines(0, before_start - 1, before_end, false)
	end
	if after_end >= after_start then
		after_lines = vim.api.nvim_buf_get_lines(0, after_start - 1, after_end, false)
	end

	return table.concat(before_lines, "\n"), table.concat(after_lines, "\n")
end

local function replace_range(range, text)
	local new_lines = vim.split(text or "", "\n", { plain = true })
	vim.api.nvim_buf_set_text(0, range.srow - 1, range.scol, range.erow - 1, range.ecol_ex, new_lines)
end

local function get_openai_token()
	local res = vim.system({ "pass", "show", "OpenAI" }, { text = true }):wait()
	if (res.code or 1) ~= 0 then
		return nil, ("Failed to read token from pass: %s"):format(res.stderr or "unknown error")
	end
	local token = (res.stdout or ""):gsub("%s+$", "")
	if token == "" then
		return nil, "OpenAI token is empty. Check `pass show OpenAI`."
	end
	return token, nil
end

local function call_openai(token, prompt, text, ctx_before, ctx_after)
	local user_payload = table.concat({
		"--- CONTEXT BEFORE (read-only) ---",
		ctx_before ~= "" and ctx_before or "(none)",
		"--- SELECTION START ---",
		text,
		"--- SELECTION END ---",
		"--- CONTEXT AFTER (read-only) ---",
		ctx_after ~= "" and ctx_after or "(none)",
		"",
		"Only modify the text between SELECTION START/END based on the system instructions.",
		"Do NOT rewrite or echo the context. Return only the final transformed selection.",
	}, "\n")

	local payload = vim.json.encode({
		model = "gpt-4o",
		temperature = 0.7,
		messages = {
			{
				role = "system",
				content = ("Transform the user provided code according to the instructions below. " ..
					"Use surrounding context as read-only to understand intent, " ..
					"but apply changes ONLY to the selected region. " ..
					"Implement the actual things when asked to. " ..
					"Return only the transformed selection—no preface, no markdown fences.\n\n%s"):format(prompt)
			},
			{
				role = "user",
				content = user_payload
			},
		},
	})

	local res = vim.system({
		"curl", "-sS", "-X", "POST", "https://api.openai.com/v1/chat/completions",
		"-H", "Content-Type: application/json",
		"-H", "Authorization: Bearer " .. token,
		"-d", payload,
	}, { text = true, timeout = 30000 }):wait()

	if (res.code or 1) ~= 0 then
		return nil, ("OpenAI request failed: %s"):format(res.stderr or "unknown error")
	end

	local ok, data = pcall(vim.json.decode, res.stdout or "")
	if not ok then
		return nil, "Failed to parse OpenAI response."
	end

	local choice = data and data.choices and data.choices[1]
	local content = choice and choice.message and choice.message.content
	if not content or content == "" then
		return nil, "OpenAI returned no content."
	end
	return content, nil
end

-- Ask mode: send entire buffer + user question, show answer in scratch window.
local function call_openai_ask(token, question, buf_text)
	local sys = table.concat({
		"You are a helpful developer assistant.",
		"Use the provided buffer as context only; do not rewrite it.",
		"Answer the user's question clearly. Include code blocks when useful.",
		"If referring to code, mention line numbers when relevant.",
	}, " ")
	local user = table.concat({
		"--- BUFFER START ---",
		buf_text,
		"--- BUFFER END ---",
		"",
		"Question:",
		question,
	}, "\n")

	local payload = vim.json.encode({
		model = "gpt-4o",
		messages = {
			{ role = "system", content = sys },
			{ role = "user", content = user },
		},
	})

	local res = vim.system({
		"curl", "-sL", "-X", "POST", "https://api.openai.com/v1/chat/completions",
		"-H", "Content-Type: application/json",
		"-H", "Authorization: Bearer " .. token,
		"-d", payload,
	}, { text = true, timeout = 30000 }):wait()

	if (res.code or 1) ~= 0 then
		return nil, ("OpenAI request failed: %s"):format(res.stderr or "unknown error")
	end

	local ok, data = pcall(vim.json.decode, res.stdout or "")
	if not ok then
		return nil, "Failed to parse OpenAI response."
	end

	local choice = data and data.choices and data.choices[1]
	local content = choice and choice.message and choice.message.content
	if not content or content == "" then
		return nil, "OpenAI returned no content."
	end
	return content, nil
end

local function show_markdown_scratch(title, md)
	-- Open a new scratch split and render as markdown
	vim.cmd("botright new")
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_name(buf, title or "GPT Answer")
	local lines = vim.split(md or "", "\n", { plain = true })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.bo[buf].modifiable = false
end

local function run_with_prompt(prompt)
	local range, rngerr = get_visual_range()
	if rngerr then
		vim.notify(rngerr, vim.log.levels.ERROR)
		return
	end

	local sel = get_visual_text(range)
	if sel == "" then
		vim.notify("No visual selection.", vim.log.levels.WARN)
		return
	end

	local ctx_before, ctx_after = get_context_lines(range, CONTEXT_BEFORE, CONTEXT_AFTER)

	local token, terr = get_openai_token()
	if not token then
		vim.notify(terr, vim.log.levels.ERROR)
		return
	end

	local out, oerr = call_openai(token, prompt, sel, ctx_before, ctx_after)
	if not out then
		vim.notify(oerr, vim.log.levels.ERROR)
		return
	end

	replace_range(range, out)
	vim.notify("Done.", vim.log.levels.INFO)
end

local function run_ask(question)
	if not question or question == "" then
		vim.notify("Usage: :GptAsk <question...>", vim.log.levels.WARN)
		return
	end

	local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local buf_text = table.concat(buf_lines, "\n")

	local token, terr = get_openai_token()
	if not token then
		vim.notify(terr, vim.log.levels.ERROR)
		return
	end

	local out, oerr = call_openai_ask(token, question, buf_text)
	if not out then
		vim.notify(oerr, vim.log.levels.ERROR)
		return
	end

	show_markdown_scratch("GPT Answer", out)
end

function M.setup()
	vim.api.nvim_create_user_command("Ai", function(opts)
		local prompt = opts.args or ""
		if prompt == "" then
			vim.notify("Usage: :Gpt <prompt...> (run from Visual selection)", vim.log.levels.WARN)
			return
		end
		run_with_prompt(prompt)
	end, {
		nargs = "*",
		range = true,
	})

	vim.api.nvim_create_user_command("Ask", function(opts)
		run_ask(opts.args or "")
	end, {
		nargs = "+",
		range = true,
	})

	vim.keymap.set("v", "<leader>ae", function(opts)
		vim.ui.input({prompt = "Enter prompt: "}, function(prompt)
			if prompt then
				run_with_prompt(prompt)
			end
		end)
	end, { noremap = true, silent = true })

	vim.keymap.set("v", "<leader>aa", function(opts)
		vim.ui.input({prompt = "Question: "}, function(prompt)
			if prompt then
				run_ask(prompt)
			end
		end)
	end, { noremap = true, silent = true })


end

return M

