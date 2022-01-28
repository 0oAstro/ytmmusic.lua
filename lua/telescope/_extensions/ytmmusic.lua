local yt = require("ytmmusic")

local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
    vim.notify("ytmmusic: The music picker needs nvim-telescope/telescope.nvim", vim.log.levels.ERROR)
end
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")

local mapping = {
        ["n"] = {
            ["<CR>"] = "enter",
            ["k"] = "prev_song",
            ["j"] = "next_song",
        },
        ["i"] = {
            ["<CR>"] = "enter",
            ["<S-Tab>"] = "prev_song",
            ["<Tab>"] = "next_song",
        },
}

local function get_queue()
    return yt.getQueue()
end

local function enter(prompt_bufnr)
    local selected = action_state.get_selected_entry()
    yt.parseCommand("player-set-queue", selected.index - 1)
    vim.notify("Now Playing " .. selected[1])
    actions.close(prompt_bufnr)
end

local function next_song(prompt_bufnr)
    actions.move_selection_next(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    vim.notify("Now Playing " .. selection[1])
    yt.parseCommand("player-set-queue", selection.index - 1)
end

local function prev_song(prompt_bufnr)
    actions.move_selection_previous(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    vim.notify("Now Playing " .. selection[1])
    yt.parseCommand("player-set-queue", selection.index - 1)
end

local function ytmmusic(opts)
    local queue = get_queue()
    local opts = require("telescope.themes").get_dropdown({
        prompt_title = "ytmmusic",
        results_title = "Binge your music",
        finder = finders.new_table({
            results = queue,
        }),
        previewer = false,
        attach_mappings = function(prompt_bufnr, map)
            --TODO: mappings
            for type, value in pairs(mapping) do
                for bind, method in pairs(value) do
                    map(type, bind, function()
                        if method == "enter" then
                            enter(prompt_bufnr)
                        elseif method == "next_song" then
                            next_song(prompt_bufnr)
                        elseif method == "prev_song" then
                            prev_song(prompt_bufnr)
                        end
                    end)
                end
            end
            return true
        end,
        sorter = require("telescope.config").values.generic_sorter({}),
    })
    local colorschemes = pickers.new(opts)
    colorschemes:find()
end

return telescope.register_extension({
    exports = {
        ytmmusic = ytmmusic,
    },
})
