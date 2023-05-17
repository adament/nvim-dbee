local utils = require("dbee.utils")

local DEFAULT_PERSISTENCE_FILE = vim.fn.stdpath("cache") .. "/dbee/persistence.json"

local M = {}

-- Parses json file with connections
---@param path? string path to file
---@return connection_details[]
function M.load_from_file(path)
  path = path or DEFAULT_PERSISTENCE_FILE

  ---@type connection_details[]
  local conns = {}

  if not vim.loop.fs_stat(path) then
    return {}
  end

  local lines = {}
  for line in io.lines(path) do
    if not vim.startswith(vim.trim(line), "//") then
      table.insert(lines, line)
    end
  end

  local contents = table.concat(lines, "\n")
  local ok, data = pcall(vim.fn.json_decode, contents)
  if not ok then
    utils.log("warn", 'Could not parse json file: "' .. path .. '".', "loader")
    return {}
  end

  for _, conn in pairs(data) do
    if type(conn) == "table" and conn.url and conn.type then
      table.insert(conns, conn)
    end
  end

  return conns
end

-- Parses env variable if it exists
---@param var? string env var to check - default: DBEE_CONNECTIONS
---@return connection_details[]
function M.load_from_env(var)
  var = var or "DBEE_CONNECTIONS"

  ---@type connection_details[]
  local conns = {}

  local raw = os.getenv(var)
  if not raw then
    return {}
  end

  local ok, data = pcall(vim.fn.json_decode, raw)
  if not ok then
    utils.log("warn", 'Could not parse connections from env: "' .. var .. '".', "loader")
    return {}
  end

  for _, conn in pairs(data) do
    if type(conn) == "table" and conn.url and conn.type then
      table.insert(conns, conn)
    end
  end

  return conns
end

-- appends connection_details to a json
---@param connections connection_details[]
---@param path? string path to save file
function M.add_to_file(connections, path)
  path = path or DEFAULT_PERSISTENCE_FILE

  if not connections or vim.tbl_isempty(connections) then
    return
  end

  local existing = M.load_from_file(path)

  existing = vim.list_extend(existing, connections)

  local ok, json = pcall(vim.fn.json_encode, existing)
  if not ok then
    utils.log("error", "Could not convert connection list to json", "loader")
    return
  end

  -- overwrite file
  local file = assert(io.open(path, "w+"), "could not open file")
  file:write(json)
  file:close()
end

-- removes connection_details from a json file
---@param connections connection_details[]
---@param path? string path to save file
function M.remove_from_file(connections, path)
  path = path or DEFAULT_PERSISTENCE_FILE

  if not connections or vim.tbl_isempty(connections) then
    return
  end

  local existing = M.load_from_file(path)

  for _, to_remove in ipairs(connections) do
    for i, ex_conn in ipairs(existing) do
      if to_remove.id == ex_conn.id then
        table.remove(existing, i)
      end
    end
  end

  local ok, json = pcall(vim.fn.json_encode, existing)
  if not ok then
    utils.log("error", "Could not convert connection list to json", "loader")
    return
  end

  -- overwrite file
  local file = assert(io.open(path, "w+"), "could not open file")
  file:write(json)
  file:close()
end

return M
