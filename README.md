# pm — simple package manager for ComputerCraft

Install location: `pm/` holds the package manager itself; installed projects are placed under `vx/` (e.g. `vx/<project>`). Commands are provided by `pm/init.lua`.

Usage (run inside CraftOS):

```lua
-- list available packages from ThevXTeam
shell.run("pm/init.lua", "list")

-- install a package
shell.run("pm/init.lua", "install", "repo-name")

-- remove a package
shell.run("pm/init.lua", "remove", "repo-name")

-- update a package
shell.run("pm/init.lua", "update", "repo-name")
```

Notes and limitations:
- Requires the `http` API to be enabled in CC:Tweaked/CraftOS-PC.
- This implementation downloads files via `raw.githubusercontent.com` using the repository tree.
- Some repos use submodules, git-lfs, or non-raw-managed content — those may not install correctly.
- If you hit GitHub rate limits, set `token` in `pm/config.lua` to `"token YOUR_TOKEN"`.

Next improvements you might want:
- Add dependency metadata parsing (e.g., a `pm.json` in repos).
- Add concurrency throttling and retry logic.
- Add a simple index cache to avoid querying GitHub every time.
