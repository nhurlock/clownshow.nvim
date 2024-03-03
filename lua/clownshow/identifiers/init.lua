local Object = require("clownshow.object")
local Parser = require("clownshow.identifiers.parser")
local Identifier = require("clownshow.identifiers.identifier")

---@class ClownshowIdentifiers
---@field _bufnr number
---@field identifiers table<number, ClownshowIdentifier>
---@overload fun(bufnr: number): ClownshowIdentifiers
local Identifiers = Object("ClownshowIdentifiers")

---@param bufnr number
function Identifiers:init(bufnr)
  self._bufnr = bufnr
  self._parser = Parser(bufnr)
  self.identifiers = {}
end

function Identifiers:get()
  return self.identifiers
end

---@param line number
---@return ClownshowIdentifier?
function Identifiers:get_by_line(line)
  return self.identifiers[line]
end

---@param props ClownshowIdentifierProps
---@return ClownshowIdentifier
function Identifiers:create(props)
  self.identifiers[props.line] = Identifier(props, function(i)
    return self:get_by_line(i.parent)
  end)
  return self.identifiers[props.line]
end

function Identifiers:update()
  self:reset()
  for _, identifier in ipairs(self._parser:get_identifiers()) do
    self:create(identifier)
  end
end

function Identifiers:reset()
  self.identifiers = {}
end

return Identifiers
