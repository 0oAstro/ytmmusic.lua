local Job = require("plenary.job")

local function get_line(filename, line_number)
  local i = 0
  for line in io.lines(filename) do
    i = i + 1
    if i == line_number then
      return line
    end
  end
  return nil -- line not found
end

local function read_auth_file(path)
	local auth = get_line(path, 1)
  if not auth then
		vim.notify(
			[[
ytmmusic.lua: Auth file not found.
You will need to add your ytmdesktop integration password in ~/.config/nvim/ytmmusic_auth file.
Please create auth file and then continue]],
			vim.log.levels.ERROR
		)
		return nil
	end
    return auth
end

local yt = {}
local auth = read_auth_file(vim.fn.stdpath("config") .. "/ytmmusic_auth")
-- ytmdesktop -setting integreation password should be there

local makeReq = function(url)
	local req = Job
		:new({
			command = "curl",
			args = { url },
		})
		:sync()
	return vim.json.decode(req[1] or "")
end

yt.parseCommand = function(command, value)
  local cmd = string.format([[silent !curl -H "Authorization: Bearer %s" -X POST -d '{"command": "%s", "value": "%s"}' http://localhost:9863/query]], auth, command, value)
  vim.cmd(cmd)
end

local rounder = function(num, places)
	local mult = 10 ^ (places or 0)
	return (math.floor(num * mult + 0.5) / mult) * 100
end

yt.getCurrentStats = function()
	local currentStats = makeReq("http://localhost:9863/query")
	return currentStats
end

yt.notifyCurrentStats = function()
	local currentStats = yt.getCurrentStats()
  
  local message = string.format(
			[[
Currently Playing: %s
Artist: %s
Percentage %s%s of %s
Current Position: %s]],
			currentStats.track.title,
			currentStats.track.author,
			rounder(currentStats.player.statePercent, 3),
			"%",
			currentStats.track.durationHuman,
      currentStats.player.seekbarCurrentPositionHuman
		)
  if currentStats.player.isPaused then
    message = message:gsub("Currently Playing", "Currently Paused")
  end
  vim.notify(message, vim.log.levels.INFO)
end

yt.getNthStats = function(prev_or_next)
	local returnStats = makeReq("http://localhost:9863/query/queue")

	-- Index 0 = previous track , 1 == current 2 == next
	local currentIndex = returnStats.currentIndex + prev_or_next
	local trackCover
	local trackTitle
	local trackAuthor
	local trackDuration

	local indexedValue = returnStats.list[currentIndex]

	for k, v in pairs(indexedValue) do
		if k == "cover" then
			trackCover = v
		elseif k == "title" then
			trackTitle = v
		elseif k == "author" then
			trackAuthor = v
		elseif k == "duration" then
			trackDuration = v
		end
	end

	return {
		currentIndex = currentIndex,
		trackCover = trackCover,
		trackTitle = trackTitle,
		trackAuthor = trackAuthor,
		trackDuration = trackDuration,
	}
end

yt.notifyNextStats = function()
	local nextStats = yt.getNthStats(2)

	vim.notify(
		string.format(
			"Next Track: %s\nArtist: %s\nDuration: %s",
			nextStats.trackTitle,
			nextStats.trackAuthor,
			nextStats.trackDuration
		)
	)
end

yt.notifyPrevStats = function()
	local nextStats = yt.getNthStats(0)

	vim.notify(
		string.format(
			"Prev Track was: %s\nArtist: %s\nDuration: %s",
			nextStats.trackTitle,
			nextStats.trackAuthor,
			nextStats.trackDuration
		)
	)
end

yt.getQueue = function ()
  local queue = makeReq("http://localhost:9863/query/queue").list
  local queue_tracks = {}
  for trackNumber = 1, #queue do
    table.insert(queue_tracks, string.format("%s by %s", queue[trackNumber].title, queue[trackNumber].author))
  end
  return queue_tracks
end

yt.sendCommand = function (cmd, value)
  yt.parseCommand(cmd, value)
  vim.notify(string.format([[ytmmusic.lua: Successfully ran command %s]], cmd))
end

return yt
