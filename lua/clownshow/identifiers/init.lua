local Object = require("clownshow.object")
local Parser = require("clownshow.identifiers.parser")
local Identifier = require("clownshow.identifiers.identifier")

---@class ClownshowIdentifiers
---@field _bufnr number
---@field _parser ClownshowIdentifierParser
---@field identifiers table<number, ClownshowIdentifier>
---@overload fun(bufnr: number): ClownshowIdentifiers
local Identifiers = Object("ClownshowIdentifiers")

-- creates an identifiers tracker for the buffer
---@param bufnr number buffer to track identifiers for
function Identifiers:init(bufnr)
  self._bufnr = bufnr
  self._parser = Parser(bufnr)
  self.identifiers = {}
end

-- gets the tracked identifiers
---@return table<number, ClownshowIdentifier> identifiers tracked identifiers { [line] = props }
function Identifiers:get()
  return self.identifiers
end

-- gets an identifier by line number
---@param line number line to check
---@return ClownshowIdentifier? identifier identifier found at line
function Identifiers:get_by_line(line)
  return self.identifiers[line]
end

-- creates a new tracked identifier
---@param props ClownshowIdentifierProps identifier properties
---@return ClownshowIdentifier identifier the new identifier
function Identifiers:create(props)
  self.identifiers[props.line] = Identifier(props, function(i)
    return self:get_by_line(i.parent)
  end)
  return self.identifiers[props.line]
end

-- resets the stats for all identifiers
function Identifiers:reset_stats()
  for _, identifier in pairs(self.identifiers) do
    identifier:reset_stats()
  end
end

-- recreate the identifiers for the buffer
function Identifiers:update()
  self:reset()
  for _, identifier in ipairs(self._parser:get_identifiers()) do
    self:create(identifier)
  end
end

-- clear tracked identifiers
function Identifiers:reset()
  self.identifiers = {}
end

return Identifiers
