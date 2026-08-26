local M = {}

local defaults = {
  codex_cmd = "codex",
  model = nil,
  sandbox = "read-only",
  approval = "never",
  extra_args = {},
  terminal_args = {},
  window = {
    width = 0.85,
    height = 0.85,
    border = "rounded",
  },
}

local config = vim.deepcopy(defaults)

local function trim(value)
  return vim.trim(value or "")
end

local function size(value, total)
  if type(value) == "number" and value > 0 and value <= 1 then
    return math.max(20, math.floor(total * value))
  end

  return math.max(20, math.floor(value or total))
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

  local win = vim.api.nvim_open_win(buf, true, opts)
  return buf, win
end

local function set_lines(buf, lines, filetype)
  vim.bo[buf].modifiable = true
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = filetype or "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
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

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Pi Agent" })
end

local function current_context(lines, label)
  if not lines or #lines == 0 then
    return ""
  end

  local file = vim.api.nvim_buf_get_name(0)
  local filetype = vim.bo.filetype
  local header = string.format(
    "\n\n<context source=\"%s\" file=\"%s\" filetype=\"%s\">\n",
    label,
    file,
    filetype
  )

  return header .. table.concat(lines, "\n") .. "\n</context>"
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

local function build_exec_cmd(cwd)
  local cmd = {
    config.codex_cmd,
    "exec",
    "--skip-git-repo-check",
    "--cd",
    cwd,
    "--color",
    "never",
  }

  if config.model then
    vim.list_extend(cmd, { "--model", config.model })
  end

  if config.sandbox then
    vim.list_extend(cmd, { "--sandbox", config.sandbox })
  end

  if config.approval then
    vim.list_extend(cmd, { "--ask-for-approval", config.approval })
  end

  vim.list_extend(cmd, config.extra_args)
  table.insert(cmd, "-")

  return cmd
end

function M.exec(prompt, opts)
  opts = opts or {}
  prompt = trim(prompt)

  if prompt == "" then
    prompt_with_input("Pi Agent prompt: ", function(input)
      M.exec(input, opts)
    end)
    return
  end

  if not command_exists(config.codex_cmd) then
    notify("codex CLI was not found in PATH.", vim.log.levels.ERROR)
    return
  end

  local cwd = opts.cwd or vim.fn.getcwd()
  local buf = open_float(opts.title or "Pi Agent")
  set_lines(buf, { "Running Codex..." }, "markdown")

  local stdout = {}
  local stderr = {}
  local job_id

  job_id = vim.fn.jobstart(build_exec_cmd(cwd), {
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
        local lines = {}

        if #stdout > 0 then
          vim.list_extend(lines, stdout)
        end

        if code ~= 0 and #stderr > 0 then
          if #lines > 0 then
            table.insert(lines, "")
          end
          table.insert(lines, "Codex returned an error:")
          table.insert(lines, "")
          vim.list_extend(lines, stderr)
        elseif code == 0 and #stderr > 0 then
          if #lines > 0 then
            table.insert(lines, "")
          end
          vim.list_extend(lines, stderr)
        end

        if #lines == 0 then
          table.insert(lines, "Codex finished with no output.")
        end

        set_lines(buf, lines, "markdown")
        if code ~= 0 then
          notify("Codex exited with code " .. code .. ".", vim.log.levels.ERROR)
        end
      end)
    end,
  })

  if job_id <= 0 then
    notify("Failed to start codex.", vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(job_id, prompt)
  vim.fn.chanclose(job_id, "stdin")
end

function M.ask(prompt)
  M.exec(prompt, { title = "Pi Agent Ask" })
end

function M.buffer(prompt)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local full_prompt = trim(prompt)

  local function run(input)
    M.exec(input .. current_context(lines, "buffer"), { title = "Pi Agent Buffer" })
  end

  if full_prompt == "" then
    prompt_with_input("Pi Agent buffer prompt: ", run)
  else
    run(full_prompt)
  end
end

function M.selection(prompt, line1, line2)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  local full_prompt = trim(prompt)

  local function run(input)
    M.exec(input .. current_context(lines, "selection"), { title = "Pi Agent Selection" })
  end

  if full_prompt == "" then
    prompt_with_input("Pi Agent selection prompt: ", run)
  else
    run(full_prompt)
  end
end

function M.open(prompt)
  if not command_exists(config.codex_cmd) then
    notify("codex CLI was not found in PATH.", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local cmd = { config.codex_cmd, "--cd", cwd }
  vim.list_extend(cmd, config.terminal_args)

  prompt = trim(prompt)
  if prompt ~= "" then
    table.insert(cmd, prompt)
  end

  local buf = open_float("Pi Agent Terminal")
  vim.fn.termopen(cmd, { cwd = cwd })
  vim.bo[buf].bufhidden = "wipe"
  vim.cmd("startinsert")
end

function M.login()
  if not command_exists(config.codex_cmd) then
    notify("codex CLI was not found in PATH.", vim.log.levels.ERROR)
    return
  end

  local buf = open_float("Pi Agent Login")
  vim.fn.termopen({ config.codex_cmd, "login", "--device-auth" })
  vim.bo[buf].bufhidden = "wipe"
  vim.cmd("startinsert")
end

function M.status()
  if not command_exists(config.codex_cmd) then
    notify("codex CLI was not found in PATH.", vim.log.levels.ERROR)
    return
  end

  local buf = open_float("Pi Agent Status")
  set_lines(buf, { "Checking Codex status..." }, "markdown")

  local stdout = {}
  local stderr = {}

  local job_id = vim.fn.jobstart({ config.codex_cmd, "login", "status" }, {
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
        local lines = { "```text", "$ codex login status" }

        if #stdout > 0 then
          table.insert(lines, "")
          vim.list_extend(lines, stdout)
        end

        if #stderr > 0 then
          table.insert(lines, "")
          vim.list_extend(lines, stderr)
        end

        table.insert(lines, "```")
        set_lines(buf, lines, "markdown")

        if code ~= 0 then
          notify("Codex status check exited with code " .. code .. ".", vim.log.levels.WARN)
        end
      end)
    end,
  })

  if job_id <= 0 then
    notify("Failed to start codex.", vim.log.levels.ERROR)
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  vim.api.nvim_create_user_command("PiAgent", function(command)
    M.open(command.args)
  end, { nargs = "*", desc = "Open Codex in a floating terminal" })

  vim.api.nvim_create_user_command("PiAgentAsk", function(command)
    M.ask(command.args)
  end, { nargs = "*", desc = "Ask Codex and show the response" })

  vim.api.nvim_create_user_command("PiAgentBuffer", function(command)
    M.buffer(command.args)
  end, { nargs = "*", desc = "Ask Codex with the current buffer as context" })

  vim.api.nvim_create_user_command("PiAgentSelection", function(command)
    M.selection(command.args, command.line1, command.line2)
  end, { nargs = "*", range = true, desc = "Ask Codex with selected lines as context" })

  vim.api.nvim_create_user_command("PiAgentLogin", function()
    M.login()
  end, { desc = "Run codex login --device-auth" })

  vim.api.nvim_create_user_command("PiAgentStatus", function()
    M.status()
  end, { desc = "Check Codex authentication status" })
end

return M
