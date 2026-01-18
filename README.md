# pm — simple package manager for ComputerCraft

Install location: `pm/` holds the package manager itself; installed projects are placed under `vx/` (e.g. `vx/<project>`). Commands are provided by `pm/init.lua`.

Usage (run inside CraftOS):

```lua
-- list available packages from ThevXTeam
pm list

-- install a package
pm install <repo-name>

-- remove a package
pm remove <repo-name>

-- update a package
pm update <repo-name>
```

Notes and limitations:
- Requires the `http` API to be enabled in CC:Tweaked/CraftOS-PC.
- This implementation downloads files via `raw.githubusercontent.com` using the repository tree.
- Some repos use submodules, git-lfs, or non-raw-managed content — those may not install correctly.
- If you hit GitHub rate limits, set `token` in `pm/config.lua` to `"token YOUR_TOKEN"`.