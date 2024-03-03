local M = {}

---@param a string
---@param b string
---@return string
function M.space_between(a, b)
  if #a > 0 and #b > 0 then
    return a .. " " .. b
  else
    return a .. b
  end
end

---@param filename string
---@return string
function M.get_file(filename)
  local file = assert(io.open(filename, "rb"))
  local content = file:read("*all")
  file:close()
  return content
end

---@param bufnr number
---@return string
function M.get_filetype(bufnr)
  return vim.bo[bufnr].filetype
end

return M
