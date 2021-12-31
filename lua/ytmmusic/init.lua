local Job = require("plenary.job")

local yt = {}

local makeReq = function(url)
	local req = Job:new({
		command = "curl",
		args = { url },
	}):sync()
	return vim.json.decode(req[1] or '')
end

yt.getCurrentStats = function()
	local currentStats = makeReq("http://localhost:9863/query")
	return currentStats
end

yt.notifyCurrentStats = function()
	local currentStats = yt.getCurrentStats()
	vim.notify(string.format("Currently Playing: %s\nArtist: %s", currentStats.track.title, currentStats.track.author))
end

return yt
