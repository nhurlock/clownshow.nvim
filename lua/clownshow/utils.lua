local M = {}

---@generic T1: table
---@generic T2: table
---@param t1 T1
---@param t2 T2
---@return T1|T2
function M.merge_tables(t1, t2)
  return vim.tbl_deep_extend("force", t1, t2)
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
