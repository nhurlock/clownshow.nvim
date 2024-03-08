local Config = require("clownshow.config")
local utils = require("clownshow.utils")

local M = {}

---@alias ClownshowMarkPartial { [0]: string, [1]: string }

-- creates a mark partial for an identifier based on its status
---@param identifier ClownshowIdentifier identifier to create mark for
---@param status? ClownshowIdentifierStatus status to get stats for
---@param force? boolean force create a mark
---@return ClownshowMarkPartial? partial mark info
function M.status_mark(identifier, status, force)
  local _status = status or identifier.status
  local stat = identifier:get_stat(_status)
  if stat == 0 and _status ~= "loading" and force ~= true then return end

  local config = Config.opts
  ---@type ClownshowStatusOptions
  local mark_options = config[_status] or config.skipped

  -- create mark text
  local mark_text = ""
  if config.show_icon then
    mark_text = mark_text .. mark_options.icon
  end
  -- apply a count for the status on "each" (tables) and "root"/"describe" blocks
  -- "each" will always have an "above" which allows us to use it as an exception to non-"test"
  if stat > 1 or ((identifier.type ~= "test" or identifier.above ~= nil) and stat > 0) then
    mark_text = utils.space_between(mark_text, tostring(stat))
  end
  if config.show_text then
    mark_text = utils.space_between(mark_text, mark_options.text)
  end

  -- apply mark padding
  if #mark_text > 0 then
    mark_text = mark_text .. " "
  end

  return { mark_text, mark_options.hl_group }
end

return M
