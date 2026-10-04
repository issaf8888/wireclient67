-- ====================================================================
-- WireWin Hub - Executor Loader
-- ====================================================================
-- Kopiere diesen Code in deinen Executor (Solara, Wave, Delta, etc.)
-- Sobald du das Repo auf GitHub hochgeladen hast, trage deinen Namen ein:

local GITHUB_USER   = "issaf8888"
local GITHUB_REPO   = "wireclient67"
local GITHUB_BRANCH = "main"

local url = string.format("https://raw.githubusercontent.com/%s/%s/%s/main.lua", GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH)

print("[WireWin] Lade Hauptskript von GitHub...")
loadstring(game:HttpGet(url, true))()
