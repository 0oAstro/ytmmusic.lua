local Job = require("plenary.job")

local yt = {}
local auth = "" -- ytmdesktop -setting integreation password should be there

local makeReq = function(url)
  local req = Job
    :new({
      command = "curl",
      args = { url },
    })
    :sync()
  return vim.json.decode(req[1] or "")
end

local sendReq = function(command, url)
  Job
    :new({
      command = "curl",
      args = {
        "-H",
        "Authorization: Bearer " .. auth,
        "-X",
        "POST",
        "-d",
        command,
        url,
      },
    })
    :sync()
end

local rounder = function(num, places)
  local mult = 10 ^ (places or 0)
  return (math.floor(num * mult + 0.5) / mult) * 100
end

yt.getCurrentStats = function()
  local currentStats = makeReq("http://localhost:9863/query")
  return currentStats
end

yt.notifycurrentstats = function()
  local currentStats = yt.getCurrentStats()

  vim.notify(
    string.format(
      "Currently Playing: %s\nArtist: %s\nPercentage %s%s of %s",
      currentStats.track.title,
      currentStats.track.author,
      rounder(currentStats.player.statePercent, 3),
      "%",
      currentStats.track.durationHuman
    )
  )
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

yt.notifynextstats = function()
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

yt.notifyprevstats = function()
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

yt.parseCommand = function(controlCommand)
  local command = '{"command":"' .. controlCommand .. '"}'
  local url = "http://localhost:9863/query"
  sendReq(command, url)
end

yt.test = function()
  yt.parseCommand("track-pause")
end

return yt
