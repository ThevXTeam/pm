-- pm: simple package manager for ComputerCraft
local fs = fs
local shell = shell
local textutils = textutils
local repo = require("repo")
local config = require("config")

local function usage()
  print("pm list")
  print("pm install <repo>")
  print("pm remove <repo>")
  print("pm update <repo>")
end

local function ensureInstallPath()
  if not fs.exists(config.installPath) then fs.makeDir(config.installPath) end
end

local function list()
  local repos, err = repo.listRepos()
  if not repos then print("Error listing repos:", err); return end

  local term_ok, w, h = pcall(function() return term.getSize() end)
  local width = 80
  if term_ok and w then width = w end

  -- build rows and determine column sizes
  local rows = {}
  local maxName = #"program"
  local statusWidth = #"status"
  for i=1,#repos do
    local r = repos[i]
    if r and r.name then
      local name = r.name
      local desc = r.description or ""
      local status = "available"
      local instPath = fs.combine(config.installPath, name)
      if fs.exists(instPath) then status = "installed" end
      if #name > maxName then maxName = #name end
      if #status > statusWidth then statusWidth = #status end
      table.insert(rows, {name=name, status=status, desc=desc})
    end
  end

  -- allocate widths: separators ' | ' twice = 6 chars
  local sepTotal = 6
  local progCol = math.min(maxName, math.max(6, math.floor(width * 0.25)))
  local statCol = math.max(statusWidth, 9)
  local descCol = width - progCol - statCol - sepTotal
  if descCol < 8 then
    -- shrink program column if needed
    local extra = 8 - descCol
    progCol = math.max(6, progCol - extra)
    descCol = width - progCol - statCol - sepTotal
    if descCol < 0 then descCol = 0 end
  end

  -- header
  local header = string.format("%-"..progCol.."s | %-"..statCol.."s | %s", "program", "status", "description")
  print(header)
  local sep = {}
  for i=1,#header do
    local ch = header:sub(i,i)
    if ch == '|' then sep[i] = '+' else sep[i] = '-' end
  end
  print(table.concat(sep))

  for i=1,#rows do
    local r = rows[i]
    local desc = r.desc or ""
    if #desc > descCol then
      if descCol > 3 then
        desc = desc:sub(1, descCol-3) .. "..."
      else
        desc = desc:sub(1, descCol)
      end
    end
    print(string.format("%-"..progCol.."s | %-"..statCol.."s | %s", r.name, r.status, desc))
  end
end

local function makeDirsForPath(base, path)
  local parts = {}
  for p in string.gmatch(path, "([^\"]+/?)") do
    table.insert(parts, p)
  end
  -- simpler: iterate path segments
  local accum = base
  for seg in string.gmatch(path, "([^\"]+)/") do
    accum = fs.combine(accum, seg)
    if not fs.exists(accum) then fs.makeDir(accum) end
  end
end

local function install(repoName)
  if not repoName then print("specify repo"); return end
  ensureInstallPath()
  local ok, err = pcall(function()
    local info = repo.getRepoTree(nil, repoName, nil)
    if not info then error("failed to get tree") end
    local basePath = fs.combine(config.installPath, repoName)
    if fs.exists(basePath) then print("Package already installed at ", basePath); return end
    fs.makeDir(basePath)
    for i=1,#info.tree do
      local node = info.tree[i]
      if node.type == "blob" then
        -- create dirs
        local dir = node.path:match("(.*/)")
        if dir then
          local fullDir = fs.combine(basePath, dir)
          if not fs.exists(fullDir) then fs.makeDir(fullDir) end
        end
        local content, err = repo.fetchRaw(nil, repoName, info.truncated and "master" or (info.url and "master" or "master"), node.path)
        if not content then print("Failed to fetch", node.path, err) else
          local outPath = fs.combine(basePath, node.path)
          local f = fs.open(outPath, "w")
          f.write(content)
          f.close()
        end
      end
    end
    -- execute the alias script if present
    local aliasPath = fs.combine(basePath, "alias.lua")
    if fs.exists(aliasPath) then
      local aliasFunc = loadfile(aliasPath)
      if aliasFunc then
        local ok, err = pcall(aliasFunc)
        if not ok then print("Error running alias script:", err) end
      end
    end
    print("Installed: " .. repoName)
  end)
  if not ok then print("Install failed:") print(err) end
end

local function remove(repoName)
  if not repoName then print("specify repo"); return end
  local basePath = fs.combine(config.installPath, repoName)
  if not fs.exists(basePath) then print("Package not installed") return end
  shell.execute("delete " .. basePath) -- try shell delete; fallback below
  if fs.exists(basePath) then
    -- recursive delete
    local function rrm(p)
      for _,v in pairs(fs.list(p)) do
        local full = fs.combine(p, v)
        if fs.isDir(full) then rrm(full) else fs.delete(full) end
      end
      fs.delete(p)
    end
    rrm(basePath)
  end
  print("Removed: " .. repoName)
end

local function update(repoName)
  remove(repoName)
  install(repoName)
end

-- CLI entry
local args = {...}
local cmd = args[1]
if not cmd then usage(); return end
if cmd == "list" then list()
elseif cmd == "install" then install(args[2])
elseif cmd == "remove" then remove(args[2])
elseif cmd == "update" then update(args[2])
else usage() end
