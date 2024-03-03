local Object = require("clownshow.object")

---@alias ClownshowIdentifierType "test"|"describe"|"root"
---@alias ClownshowIdentifierStatus "pending"|"loading"|"passed"|"failed"
---@alias ClownshowIdentifierGetParent fun(i: ClownshowIdentifier): ClownshowIdentifier?

---@class ClownshowIdentifierStats
---@field passed number
---@field failed number
---@field pending number

---@class ClownshowIdentifierAbove
---@field line number
---@field col number

---@class ClownshowIdentifierProps
---@field line number
---@field col number
---@field endline? number
---@field type? ClownshowIdentifierType
---@field status? ClownshowIdentifierStatus
---@field only? boolean
---@field has_only? boolean
---@field parent? number
---@field above? ClownshowIdentifierAbove

---@class ClownshowIdentifier
---@field line number
---@field col number
---@field endline? number
---@field type? ClownshowIdentifierType
---@field status? ClownshowIdentifierStatus
---@field mark? number
---@field only? boolean
---@field has_only? boolean
---@field parent? number
---@field above? ClownshowIdentifierAbove
---@field _stats ClownshowIdentifierStats
---@field _get_parent ClownshowIdentifierGetParent
---@overload fun(props: ClownshowIdentifierProps, get_parent?: ClownshowIdentifierGetParent): ClownshowIdentifier
local Identifier = Object("ClownshowIdentifier")

---@param props ClownshowIdentifierProps
---@param get_parent? ClownshowIdentifierGetParent
function Identifier:init(props, get_parent)
  self.line = props.line
  self.col = props.col
  self.endline = props.endline
  self.type = props.type
  self.status = props.status
  self.only = props.only
  self.has_only = props.has_only
  self.parent = props.parent
  self.above = props.above
  self._get_parent = get_parent or function() end
  self:reset_stats()
end

---@param status ClownshowIdentifierStatus
function Identifier:_inc_stat(status)
  self._stats[status] = (self._stats[status] or 0) + 1

  local parent = self:get_parent()
  if parent then
    parent:_inc_stat(status)
  end
end

---@return number, number, number?
function Identifier:get_pos()
  return self.line, self.col, self.endline
end

---@return ClownshowIdentifier?
function Identifier:get_parent()
  return self._get_parent(self)
end

---@param status? ClownshowIdentifierStatus
function Identifier:get_stat(status)
  return self._stats[status or self.status] or 0
end

function Identifier:reset_stats()
  self._stats = { passed = 0, failed = 0, pending = 0 }
end

---@param status ClownshowIdentifierStatus
function Identifier:apply_status(status)
  self.status = status
  self:_inc_stat(status)
end

return Identifier
