-- repo.lua: helper functions for interacting with GitHub (for pm)
local http = http
local textutils = textutils
local config = require("config")

local M = {}

local function httpGet(url, headers)
  if not http then error("HTTP API not available; enable http in CC:Tweaked") end
  local h
  if headers then h = http.get(url, headers) else h = http.get(url) end
  if not h then return nil, "http.get failed for "..url end
  local body = h.readAll()
  h.close()
  return body
end

local function apiGet(path)
  local url = config.github_api .. path
  local headers = nil
  if config.token then headers = { ["Authorization"] = config.token } end
  local body, err = httpGet(url, headers)
  if not body then return nil, err end
  local ok, j = pcall(textutils.unserializeJSON, body)
  if not ok then return nil, "failed to parse JSON" end
  return j
end

function M.listRepos(owner)
  owner = owner or config.owner
  local page = 1
  local all = {}
  while true do
    local res, err = apiGet(string.format("/users/%s/repos?per_page=100&page=%d", owner, page))
    if not res then return nil, err end
    for i=1,#res do table.insert(all, res[i]) end
    if #res < 100 then break end
    page = page + 1
  end
  return all
end

function M.getRepoTree(owner, repo, branch)
  owner = owner or config.owner
  branch = branch or "main"
  local path = string.format("/repos/%s/%s/git/trees/%s?recursive=1", owner, repo, branch)
  local res, err = apiGet(path)
  if not res then return nil, err end
  return res
end

function M.fetchRaw(owner, repo, branch, filepath)
  owner = owner or config.owner
  branch = branch or "main"
  local url = string.format("%s/%s/%s/%s/%s", config.raw_base, owner, repo, branch, filepath)
  local body, err = httpGet(url)
  if not body then return nil, err end
  return body
end

return M
