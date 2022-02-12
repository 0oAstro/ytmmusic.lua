-- notify about current song
vim.cmd([[command! -nargs=0 YtNotifyCurrent :lua require("ytmmusic").notifyCurrentStats()]])

-- notify next song
vim.cmd([[command! -nargs=0 YtNotifyNext :lua require("ytmmusic").notifyNextStats()]])

-- notify previous song
vim.cmd([[command! -nargs=0 YtNotifyPrevious :lua require("ytmmusic").notifyPrevStats()]])

-- Option to change volume of music
-- valid commands:
--   set volume <volume>
--   up volume <volume> or null
--   down volume <volume> or null
vim.cmd([[command! -nargs=* YtVolumeControl :lua require("ytmmusic").volumeControl(<f-args>)]])
