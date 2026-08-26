local M = {}

local defaults = {
  agent_cmd = nil,
  model = nil,
  effort = nil,
  speed = nil,
  sandbox = "read-only",
  approval = "never",
  extra_args = {},
  terminal_args = {},
  system_prompt = "You are Pi Agent, a concise AI coding assistant running inside Neovim.",
  window = {
    width = 0.85,
    height = 0.85,
    border = "rounded",
  },
  chat = {
    width = 0.38,
    min_width = 52,
    storage_dir = nil,
  },
  mappings = {
    submit = "<CR>",
    close = "q",
  },
}

local config = vim.deepcopy(defaults)

local state = {
  chat = nil,
  chats = {},
  active_root = nil,
  metadata = {
    loaded = false,
    model = nil,
    effort = nil,
    speed = nil,
  },
}

local function trim(value)
  return vim.trim(value or "")
end

local function split_lines(text)
  text = text or ""
  if text == "" then
    return {}
  end

  return vim.split(text, "\n", { plain = true })
end

local function size(value, total)
  if type(value) == "number" and value > 0 and value <= 1 then
    return math.max(20, math.floor(total * value))
  end

  return math.max(20, math.floor(value or total))
end

local function configure_buffer(buf, filetype)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = filetype or "markdown"
end

local function set_lines(buf, lines, filetype, modifiable)
  vim.bo[buf].modifiable = true
  configure_buffer(buf, filetype)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = modifiable == true
end

local function append_lines(buf, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
end

local function extend_lines(target, data)
  if not data then
    return
  end

  for index, line in ipairs(data) do
    if not (index == #data and line == "") then
      table.insert(target, line)
    end
  end
end

local function command_exists(name)
  return vim.fn.executable(name) == 1
end

local function normalize_path(path)
  path = vim.fn.expand(path or vim.fn.getcwd())

  if vim.fs and vim.fs.normalize then
    path = vim.fs.normalize(path)
  else
    path = vim.fn.fnamemodify(path, ":p")
  end

  if path ~= "/" then
    path = path:gsub("/+$", "")
  end

  return path
end

local function buffer_dir(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)

  if name ~= "" then
    if vim.fn.isdirectory(name) == 1 then
      return normalize_path(name)
    end

    return normalize_path(vim.fn.fnamemodify(name, ":p:h"))
  end

  return normalize_path(vim.fn.getcwd())
end

local function project_root(start)
  start = normalize_path(start or vim.fn.getcwd())

  local ok, lines = pcall(vim.fn.systemlist, { "git", "-C", start, "rev-parse", "--show-toplevel" })
  if ok and vim.v.shell_error == 0 and lines and lines[1] and trim(lines[1]) ~= "" then
    return normalize_path(lines[1])
  end

  return start
end

local function root_for_context(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  if vim.api.nvim_buf_is_valid(buf) then
    local ok, root = pcall(function()
      return vim.b[buf].pi_agent_root
    end)
    if ok and root and root ~= "" then
      return root
    end
  end

  return project_root(buffer_dir(buf))
end

local function chat_storage_dir()
  local configured = config.chat and config.chat.storage_dir
  if configured and configured ~= "" then
    return normalize_path(configured)
  end

  return normalize_path(vim.fn.stdpath("data") .. "/pi-agent/chats")
end

local function chat_path(root)
  return chat_storage_dir() .. "/" .. vim.fn.sha256(root) .. ".json"
end

local function new_chat(root)
  return {
    root = root,
    buf = nil,
    messages = {},
    input_start = nil,
    running = false,
    started_at = nil,
    last_response = nil,
  }
end

local function load_chat(root)
  local chat = new_chat(root)
  local path = chat_path(root)

  if vim.fn.filereadable(path) ~= 1 then
    return chat
  end

  local ok_read, lines = pcall(vim.fn.readfile, path)
  if not ok_read then
    return chat
  end

  local ok_decode, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok_decode or type(data) ~= "table" then
    return chat
  end

  if type(data.messages) == "table" then
    for _, message in ipairs(data.messages) do
      if type(message) == "table" and type(message.role) == "string" and type(message.content) == "string" then
        table.insert(chat.messages, {
          role = message.role,
          content = message.content,
        })
      end
    end
  end

  if type(data.last_response) == "table" then
    chat.last_response = {
      duration_ms = tonumber(data.last_response.duration_ms) or 0,
      chars = tonumber(data.last_response.chars) or 0,
      chars_per_second = tonumber(data.last_response.chars_per_second) or 0,
    }
  end

  return chat
end

local function save_chat(chat)
  if not chat or not chat.root then
    return
  end

  local ok_encode, encoded = pcall(vim.json.encode, {
    root = chat.root,
    messages = chat.messages,
    last_response = chat.last_response,
  })
  if not ok_encode then
    return
  end

  local directory = chat_storage_dir()
  vim.fn.mkdir(directory, "p")
  pcall(vim.fn.writefile, { encoded }, chat_path(chat.root))
end

local function chat_for_root(root)
  root = project_root(root or root_for_context())

  if not state.chats[root] then
    state.chats[root] = load_chat(root)
  end

  state.active_root = root
  state.chat = state.chats[root]
  return state.chat
end

local function plugin_root()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) ~= "@" then
    return nil
  end

  return source:sub(2):gsub("/lua/pi_agent/init%.lua$", "")
end

local function resolve_agent_cmd()
  if config.agent_cmd and config.agent_cmd ~= "" then
    return config.agent_cmd
  end

  local root = plugin_root()
  if root then
    local bundled = root .. "/bin/pi-agent"
    if command_exists(bundled) then
      return bundled
    end
  end

  return "pi-agent"
end

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Pi Agent" })
end

local function as_list(value)
  if type(value) == "table" then
    return value
  end

  return { value }
end

local function now_ms()
  return math.floor(((vim.uv or vim.loop).hrtime()) / 1000000)
end

local function format_duration(ms)
  local seconds = ms / 1000
  if seconds < 10 then
    return string.format("%.1fs", seconds)
  end

  return string.format("%ds", math.floor(seconds + 0.5))
end

local function refresh_metadata()
  if state.metadata.loaded then
    return
  end

  state.metadata.loaded = true
  local agent_cmd = resolve_agent_cmd()
  if not command_exists(agent_cmd) then
    return
  end

  local ok, lines = pcall(vim.fn.systemlist, { agent_cmd, "metadata" })
  if not ok or vim.v.shell_error ~= 0 then
    return
  end

  for _, line in ipairs(lines) do
    local key, value = line:match("^([^%s]+)%s+(.+)$")
    if key and value and value ~= "" then
      state.metadata[key] = value
    end
  end
end

local function runtime_value(key)
  local configured = config[key]
  if configured and configured ~= "" then
    return configured
  end

  local detected = state.metadata[key]
  if detected and detected ~= "" then
    return detected
  end

  return "default"
end

local function last_response_label(chat)
  if chat.running and chat.started_at then
    return "running " .. format_duration(now_ms() - chat.started_at)
  end

  if not chat.last_response then
    return "not run yet"
  end

  return string.format(
    "%s, %d chars/s",
    format_duration(chat.last_response.duration_ms),
    chat.last_response.chars_per_second
  )
end

local function prompt_with_input(input_prompt, callback)
  vim.ui.input({ prompt = input_prompt }, function(input)
    input = trim(input)
    if input == "" then
      return
    end
    callback(input)
  end)
end

local function find_window(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end

  return nil
end

local function open_float(title)
  local width = math.min(size(config.window.width, vim.o.columns), vim.o.columns)
  local height = math.min(size(config.window.height, vim.o.lines - 2), vim.o.lines - 2)
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local opts = {
    relative = "editor",
    style = "minimal",
    border = config.window.border,
    width = width,
    height = height,
    row = math.max(row, 0),
    col = math.max(col, 0),
  }

  if title then
    opts.title = " " .. title .. " "
    opts.title_pos = "center"
  end

  vim.api.nvim_open_win(buf, true, opts)
  return buf
end

local function open_chat_window(root)
  local chat = chat_for_root(root or root_for_context())

  if chat.buf and vim.api.nvim_buf_is_valid(chat.buf) then
    vim.b[chat.buf].pi_agent_root = chat.root
    local win = find_window(chat.buf)
    if win then
      vim.api.nvim_set_current_win(win)
      return chat.buf, chat
    end
  else
    chat.buf = vim.api.nvim_create_buf(false, true)
    configure_buffer(chat.buf, "markdown")
  end

  vim.cmd("botright vertical new")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, chat.buf)
  vim.b[chat.buf].pi_agent_root = chat.root

  local width = size(config.chat.width, vim.o.columns)
  width = math.max(config.chat.min_width, width)
  width = math.min(width, math.max(20, vim.o.columns - 20))
  pcall(vim.api.nvim_win_set_width, win, width)

  return chat.buf, chat
end

local function current_context(lines, label, source_buf)
  if not lines or #lines == 0 then
    return ""
  end

  source_buf = source_buf or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(source_buf)
  local filetype = vim.bo[source_buf].filetype
  local header = string.format(
    "\n\n<context source=\"%s\" file=\"%s\" filetype=\"%s\">\n",
    label,
    file,
    filetype
  )

  return header .. table.concat(lines, "\n") .. "\n</context>"
end

local function build_exec_cmd(cwd)
  local cmd = {
    resolve_agent_cmd(),
    "exec",
    "--cd",
    cwd,
  }

  if config.model then
    vim.list_extend(cmd, { "--model", config.model })
  end

  if config.effort then
    vim.list_extend(cmd, { "--effort", config.effort })
  end

  if config.speed then
    vim.list_extend(cmd, { "--speed", config.speed })
  end

  if config.sandbox then
    vim.list_extend(cmd, { "--sandbox", config.sandbox })
  end

  if config.approval then
    vim.list_extend(cmd, { "--approval", config.approval })
  end

  vim.list_extend(cmd, config.extra_args)
  table.insert(cmd, "-")

  return cmd
end

local function run_agent(prompt, opts)
  opts = opts or {}
  local agent_cmd = resolve_agent_cmd()

  if not command_exists(agent_cmd) then
    notify("pi-agent backend was not found.", vim.log.levels.ERROR)
    if opts.on_exit then
      opts.on_exit(127, {}, { "pi-agent backend was not found." })
    end
    return nil
  end

  local cwd = opts.cwd or root_for_context()
  local stdout = {}
  local stderr = {}

  local job_id = vim.fn.jobstart(build_exec_cmd(cwd), {
    cwd = cwd,
    stdin = "pipe",
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      extend_lines(stdout, data)
    end,
    on_stderr = function(_, data)
      extend_lines(stderr, data)
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if opts.on_exit then
          opts.on_exit(code, stdout, stderr)
        end
      end)
    end,
  })

  if job_id <= 0 then
    notify("Failed to start pi-agent.", vim.log.levels.ERROR)
    if opts.on_exit then
      opts.on_exit(1, {}, { "Failed to start pi-agent." })
    end
    return nil
  end

  vim.fn.chansend(job_id, prompt .. "\n")
  vim.fn.chanclose(job_id, "stdin")
  return job_id
end

local function render_result(title, initial_lines)
  local buf = open_float(title)
  set_lines(buf, initial_lines, "markdown", false)
  return buf
end

local function output_lines(code, stdout, stderr)
  local lines = {}

  if #stdout > 0 then
    vim.list_extend(lines, stdout)
  end

  if #stderr > 0 then
    if #lines > 0 then
      table.insert(lines, "")
    end

    if code ~= 0 then
      table.insert(lines, "Pi Agent returned an error:")
      table.insert(lines, "")
    end

    vim.list_extend(lines, stderr)
  end

  if #lines == 0 then
    table.insert(lines, "Pi Agent finished with no output.")
  end

  return lines
end

local function strip_code_fence(lines)
  local text = trim(table.concat(lines, "\n"))
  text = text:gsub("^```[%w%p]*\n", "")
  text = text:gsub("\n```$", "")
  return split_lines(text)
end

local function first_nonempty(lines)
  for _, line in ipairs(lines) do
    line = trim(line)
    if line ~= "" and not line:match("^```") then
      return line
    end
  end

  return nil
end

local function setup_chat_keymaps(buf)
  if vim.b[buf].pi_agent_keymaps then
    return
  end

  vim.b[buf].pi_agent_keymaps = true

  for _, submit_key in ipairs(as_list(config.mappings.submit)) do
    if submit_key and submit_key ~= "" then
      vim.keymap.set("n", submit_key, function()
        M.chat_submit()
      end, { buffer = buf, desc = "Submit Pi Agent chat prompt" })

      vim.keymap.set("i", submit_key, function()
        vim.cmd("stopinsert")
        M.chat_submit()
      end, { buffer = buf, desc = "Submit Pi Agent chat prompt" })
    end
  end

  vim.keymap.set("n", config.mappings.close, function()
    M.chat_toggle(false)
  end, { buffer = buf, desc = "Close Pi Agent chat" })
end

local function render_chat(root)
  local buf, chat = open_chat_window(root)
  setup_chat_keymaps(buf)
  refresh_metadata()

  local lines = {
    "# Pi Agent Chat",
    "",
    "Root: " .. chat.root,
    string.format(
      "Model: %s | Effort: %s | Speed: %s | Last: %s",
      runtime_value("model"),
      runtime_value("effort"),
      runtime_value("speed"),
      last_response_label(chat)
    ),
    "",
  }

  for _, message in ipairs(chat.messages) do
    table.insert(lines, "## " .. message.role)
    vim.list_extend(lines, split_lines(message.content))
    table.insert(lines, "")
  end

  if chat.running then
    table.insert(lines, "## Assistant")
    table.insert(lines, "Running Pi Agent...")
    chat.input_start = nil
    set_lines(buf, lines, "markdown", false)
    return
  end

  table.insert(lines, "## You")
  chat.input_start = #lines
  table.insert(lines, "")
  set_lines(buf, lines, "markdown", true)

  local input_line = chat.input_start + 1
  pcall(vim.api.nvim_win_set_cursor, 0, { input_line, 0 })
end

local function ensure_chat(root)
  local buf, chat = open_chat_window(root)
  setup_chat_keymaps(buf)

  if vim.api.nvim_buf_line_count(buf) == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then
    render_chat(chat.root)
  end

  return buf, chat
end

local function conversation_prompt(chat)
  local parts = {
    config.system_prompt,
    "Continue this Neovim assistant chat. Answer the latest user message directly.",
  }

  for _, message in ipairs(chat.messages) do
    table.insert(parts, "")
    table.insert(parts, message.role .. ":")
    table.insert(parts, message.content)
  end

  table.insert(parts, "")
  table.insert(parts, "Assistant:")

  return table.concat(parts, "\n")
end

local function send_chat_prompt(prompt, root)
  prompt = trim(prompt)
  if prompt == "" then
    prompt_with_input("Pi Agent chat: ", function(input)
      send_chat_prompt(input, root)
    end)
    return
  end

  local chat = chat_for_root(root or root_for_context())
  ensure_chat(chat.root)
  table.insert(chat.messages, { role = "User", content = prompt })
  chat.running = true
  chat.started_at = now_ms()
  save_chat(chat)
  render_chat(chat.root)

  run_agent(conversation_prompt(chat), {
    cwd = chat.root,
    on_exit = function(code, stdout, stderr)
      chat.running = false

      local lines = output_lines(code, stdout, stderr)
      local duration_ms = math.max(now_ms() - (chat.started_at or now_ms()), 1)
      local response_text = table.concat(lines, "\n")
      chat.started_at = nil
      chat.last_response = {
        duration_ms = duration_ms,
        chars = #response_text,
        chars_per_second = math.floor((#response_text / duration_ms) * 1000 + 0.5),
      }

      table.insert(chat.messages, {
        role = "Assistant",
        content = response_text,
      })

      save_chat(chat)
      render_chat(chat.root)

      if code ~= 0 then
        notify("Pi Agent exited with code " .. code .. ".", vim.log.levels.ERROR)
      end
    end,
  })
end

function M.exec(prompt, opts)
  opts = opts or {}
  prompt = trim(prompt)
  local cwd = opts.cwd or root_for_context()

  if prompt == "" then
    prompt_with_input("Pi Agent prompt: ", function(input)
      opts.cwd = cwd
      M.exec(input, opts)
    end)
    return
  end

  local buf = render_result(opts.title or "Pi Agent", { "Running Pi Agent..." })

  run_agent(prompt, {
    cwd = cwd,
    on_exit = function(code, stdout, stderr)
      set_lines(buf, output_lines(code, stdout, stderr), "markdown", false)
      if code ~= 0 then
        notify("Pi Agent exited with code " .. code .. ".", vim.log.levels.ERROR)
      end
    end,
  })
end

function M.inline(prompt, line1, line2, has_range)
  if has_range then
    M.selection(prompt, line1, line2)
  else
    M.ask(prompt)
  end
end

function M.ask(prompt)
  M.exec(prompt, { title = "Pi Agent Inline" })
end

function M.buffer(prompt)
  local source_buf = vim.api.nvim_get_current_buf()
  local cwd = root_for_context(source_buf)
  local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
  local full_prompt = trim(prompt)

  local function run(input)
    M.exec(input .. current_context(lines, "buffer", source_buf), { title = "Pi Agent Buffer", cwd = cwd })
  end

  if full_prompt == "" then
    prompt_with_input("Pi Agent buffer prompt: ", run)
  else
    run(full_prompt)
  end
end

function M.selection(prompt, line1, line2)
  local source_buf = vim.api.nvim_get_current_buf()
  local cwd = root_for_context(source_buf)
  local lines = vim.api.nvim_buf_get_lines(source_buf, line1 - 1, line2, false)
  local full_prompt = trim(prompt)

  local function run(input)
    M.exec(input .. current_context(lines, "selection", source_buf), { title = "Pi Agent Selection", cwd = cwd })
  end

  if full_prompt == "" then
    prompt_with_input("Pi Agent selection prompt: ", run)
  else
    run(full_prompt)
  end
end

function M.edit_selection(prompt, line1, line2)
  local source_buf = vim.api.nvim_get_current_buf()
  local cwd = root_for_context(source_buf)
  local selected = vim.api.nvim_buf_get_lines(source_buf, line1 - 1, line2, false)
  local full_prompt = trim(prompt)

  local function run(input)
    local request = table.concat({
      "Edit the selected text according to the instruction.",
      "Return only the replacement text. Do not include markdown fences or explanation.",
      "",
      "Instruction:",
      input,
      current_context(selected, "selection", source_buf),
    }, "\n")

    run_agent(request, {
      cwd = cwd,
      on_exit = function(code, stdout, stderr)
        if code ~= 0 then
          render_result("Pi Agent Edit Error", output_lines(code, stdout, stderr))
          return
        end

        if not vim.api.nvim_buf_is_valid(source_buf) then
          notify("Original buffer no longer exists.", vim.log.levels.ERROR)
          return
        end

        local replacement = strip_code_fence(stdout)
        if #replacement == 0 then
          notify("Pi Agent returned no replacement text.", vim.log.levels.WARN)
          return
        end

        vim.api.nvim_buf_set_lines(source_buf, line1 - 1, line2, false, replacement)
        notify("Selection updated.")
      end,
    })
  end

  if full_prompt == "" then
    prompt_with_input("Pi Agent edit instruction: ", run)
  else
    run(full_prompt)
  end
end

function M.chat(prompt, line1, line2, has_range)
  local source_buf = vim.api.nvim_get_current_buf()
  local root = root_for_context(source_buf)
  local args = trim(prompt)
  local subcommand = args:match("^(%S+)")
  local lower = subcommand and subcommand:lower() or ""

  if lower == "toggle" then
    M.chat_toggle(nil, root)
    return
  end

  if lower == "new" or lower == "clear" then
    local chat = chat_for_root(root)
    chat.messages = {}
    chat.running = false
    chat.started_at = nil
    chat.last_response = nil
    save_chat(chat)
    render_chat(chat.root)
    return
  end

  if lower == "add" then
    M.chat_add(line1, line2, has_range, root, source_buf)
    return
  end

  if args == "" then
    ensure_chat(root)
    render_chat(root)
    return
  end

  if has_range then
    local lines = vim.api.nvim_buf_get_lines(source_buf, line1 - 1, line2, false)
    args = args .. current_context(lines, "selection", source_buf)
  end

  send_chat_prompt(args, root)
end

function M.chat_add(line1, line2, has_range, root, source_buf)
  source_buf = source_buf or vim.api.nvim_get_current_buf()
  root = root or root_for_context(source_buf)
  local lines
  local label

  if has_range then
    lines = vim.api.nvim_buf_get_lines(source_buf, line1 - 1, line2, false)
    label = "selection"
  else
    lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
    label = "buffer"
  end

  local buf = ensure_chat(root)
  append_lines(buf, split_lines(current_context(lines, label, source_buf)))
  notify("Context added to Pi Agent chat.")
end

function M.chat_submit()
  local current_buf = vim.api.nvim_get_current_buf()
  local root = root_for_context(current_buf)
  local chat = chat_for_root(root)

  if chat.running then
    notify("Pi Agent is still running.", vim.log.levels.WARN)
    return
  end

  local buf = chat.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) or not chat.input_start then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, chat.input_start, -1, false)
  local prompt = trim(table.concat(lines, "\n"))
  if prompt == "" then
    notify("Type a prompt below '## You' first.", vim.log.levels.WARN)
    return
  end

  send_chat_prompt(prompt, chat.root)
end

function M.chat_toggle(force, root)
  local chat = chat_for_root(root or root_for_context())
  local win = find_window(chat.buf)

  if force == false or win then
    if win then
      vim.api.nvim_win_close(win, true)
    end
    return
  end

  ensure_chat(chat.root)
  render_chat(chat.root)
end

function M.panel()
  render_chat(root_for_context())
end

function M.open(prompt)
  local agent_cmd = resolve_agent_cmd()
  if not command_exists(agent_cmd) then
    notify("pi-agent backend was not found.", vim.log.levels.ERROR)
    return
  end

  local cwd = root_for_context()
  local cmd = { agent_cmd, "cli", "--cd", cwd }
  vim.list_extend(cmd, config.terminal_args)

  prompt = trim(prompt)
  if prompt ~= "" then
    table.insert(cmd, prompt)
  end

  local buf = open_float("Pi Agent CLI")
  vim.fn.termopen(cmd, { cwd = cwd })
  vim.bo[buf].bufhidden = "wipe"
  vim.cmd("startinsert")
end

function M.command(prompt)
  local cwd = root_for_context()
  prompt = trim(prompt)

  local function run(input)
    local request = table.concat({
      "Generate one Neovim command for this request.",
      "Return only the command. It must start with ':' and must not execute automatically.",
      "",
      "Request:",
      input,
    }, "\n")

    local buf = render_result("Pi Agent Command", { "Generating command..." })
    run_agent(request, {
      cwd = cwd,
      on_exit = function(code, stdout, stderr)
        if code ~= 0 then
          set_lines(buf, output_lines(code, stdout, stderr), "markdown", false)
          notify("Pi Agent exited with code " .. code .. ".", vim.log.levels.ERROR)
          return
        end

        local command = first_nonempty(strip_code_fence(stdout))
        if not command then
          set_lines(buf, { "No command generated." }, "markdown", false)
          return
        end

        command = command:gsub("^:", "")
        set_lines(buf, { "Prepared command:", "", "```vim", ":" .. command, "```" }, "markdown", false)
        vim.fn.setreg("+", ":" .. command)
        vim.api.nvim_feedkeys(":" .. command, "n", false)
      end,
    })
  end

  if prompt == "" then
    prompt_with_input("Pi Agent command request: ", run)
  else
    run(prompt)
  end
end

function M.actions(line1, line2, has_range)
  local items = {
    { label = "Chat: Toggle", run = function() M.chat_toggle() end },
    { label = "Chat: New", run = function() M.chat("new") end },
    { label = "Inline: Ask", run = function() M.inline("", line1, line2, has_range) end },
    { label = "Context: Current buffer", run = function() M.buffer("") end },
    { label = "Command: Generate Vim command", run = function() M.command("") end },
    { label = "CLI: Open Pi Agent", run = function() M.open("") end },
    { label = "Auth: Login", run = function() M.login() end },
    { label = "Auth: Status", run = function() M.status() end },
  }

  if has_range then
    table.insert(items, 4, { label = "Context: Selection", run = function() M.selection("", line1, line2) end })
    table.insert(items, 5, { label = "Edit: Selection", run = function() M.edit_selection("", line1, line2) end })
    table.insert(items, 6, { label = "Chat: Add selection", run = function() M.chat_add(line1, line2, true) end })
  end

  vim.ui.select(items, {
    prompt = "Pi Agent",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      item.run()
    end
  end)
end

function M.login()
  local agent_cmd = resolve_agent_cmd()
  if not command_exists(agent_cmd) then
    notify("pi-agent backend was not found.", vim.log.levels.ERROR)
    return
  end

  local buf = open_float("Pi Agent Login")
  vim.fn.termopen({ agent_cmd, "login" })
  vim.bo[buf].bufhidden = "wipe"
  vim.cmd("startinsert")
end

function M.status()
  local agent_cmd = resolve_agent_cmd()
  if not command_exists(agent_cmd) then
    notify("pi-agent backend was not found.", vim.log.levels.ERROR)
    return
  end

  local buf = open_float("Pi Agent Status")
  set_lines(buf, { "Checking Pi Agent status..." }, "markdown", false)

  local stdout = {}
  local stderr = {}

  local job_id = vim.fn.jobstart({ agent_cmd, "status" }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      extend_lines(stdout, data)
    end,
    on_stderr = function(_, data)
      extend_lines(stderr, data)
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        local lines = { "```text", "$ pi-agent status" }

        if #stdout > 0 then
          table.insert(lines, "")
          vim.list_extend(lines, stdout)
        end

        if #stderr > 0 then
          table.insert(lines, "")
          vim.list_extend(lines, stderr)
        end

        table.insert(lines, "```")
        set_lines(buf, lines, "markdown", false)

        if code ~= 0 then
          notify("Pi Agent status check exited with code " .. code .. ".", vim.log.levels.WARN)
        end
      end)
    end,
  })

  if job_id <= 0 then
    notify("Failed to start pi-agent.", vim.log.levels.ERROR)
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  vim.api.nvim_create_user_command("PiAgentPanel", function()
    M.panel()
  end, { desc = "Open the Pi Agent panel on the right" })

  vim.api.nvim_create_user_command("PiAgent", function(command)
    M.inline(command.args, command.line1, command.line2, command.range > 0)
  end, { nargs = "*", range = true, desc = "Open the Pi Agent inline interaction" })

  vim.api.nvim_create_user_command("PiAgentChat", function(command)
    M.chat(command.args, command.line1, command.line2, command.range > 0)
  end, {
    nargs = "*",
    range = true,
    desc = "Open or use the Pi Agent chat buffer",
    complete = function()
      return { "Toggle", "New", "Clear", "Add" }
    end,
  })

  vim.api.nvim_create_user_command("PiAgentCLI", function(command)
    M.open(command.args)
  end, { nargs = "*", desc = "Open Pi Agent in a floating terminal" })

  vim.api.nvim_create_user_command("PiAgentCmd", function(command)
    M.command(command.args)
  end, { nargs = "*", desc = "Generate a Vim command with Pi Agent" })

  vim.api.nvim_create_user_command("PiAgentActions", function(command)
    M.actions(command.line1, command.line2, command.range > 0)
  end, { range = true, desc = "Open the Pi Agent action palette" })

  vim.api.nvim_create_user_command("PiAgentAsk", function(command)
    M.ask(command.args)
  end, { nargs = "*", desc = "Ask Pi Agent and show the response" })

  vim.api.nvim_create_user_command("PiAgentBuffer", function(command)
    M.buffer(command.args)
  end, { nargs = "*", desc = "Ask Pi Agent with the current buffer as context" })

  vim.api.nvim_create_user_command("PiAgentSelection", function(command)
    M.selection(command.args, command.line1, command.line2)
  end, { nargs = "*", range = true, desc = "Ask Pi Agent with selected lines as context" })

  vim.api.nvim_create_user_command("PiAgentEdit", function(command)
    M.edit_selection(command.args, command.line1, command.line2)
  end, { nargs = "*", range = true, desc = "Edit selected lines with Pi Agent" })

  vim.api.nvim_create_user_command("PiAgentLogin", function()
    M.login()
  end, { desc = "Run Pi Agent login" })

  vim.api.nvim_create_user_command("PiAgentStatus", function()
    M.status()
  end, { desc = "Check Pi Agent authentication status" })
end

return M
