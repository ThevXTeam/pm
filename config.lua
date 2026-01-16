-- pm configuration
return {
  owner = "ThevXTeam", -- GitHub owner to pull packages from
  installPath = "vx",  -- where package projects will be written locally (vx/<project>)
  github_api = "https://api.github.com",
  raw_base = "https://raw.githubusercontent.com",
  -- Optional: set a GitHub token here to increase rate limits: "token YOUR_TOKEN"
  token = nil,
}
