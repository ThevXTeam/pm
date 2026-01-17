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
  for i=1,#repos do
    local r = repos[i]
    if r.name and r.description then
      print(string.format("%-10s - %s", r.name, r.description))
    else
      print(r.name)
    end
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
