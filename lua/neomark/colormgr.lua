local Util = require('neomark.util')
local M = {}
M.head = nil
M.tail = nil
M.unused = nil

M.keywords = {}
M.selected = 1


function M.create(num)
  if (num < 1) then
    Util.warn("num must greater than 0")
    return
  end
  local list = nil
  list = {next = list, value = num}
  M.tail = list
  if num >= 2 then
    for i = num - 1, 1, -1 do
      list = {next = list, value = i}
    end
  end
  M.head = list
  M.unused = list
end

function M.clear()
  for _, kw in ipairs(M.keywords) do
    if kw ~= "" then
      M.remove(kw)
    end
  end
end

function M.remove(word)
  word = word or ("<" .. vim.fn.expand("<cword>") .. ">")
  local index = M.is_keyword(word)
  if index == 0 then
    return
  end
  M.keywords[index] = ''
  if M.head.value == index then
    M.head = M.head.next
  elseif M.tail.value == index then
    -- do nothing
  else
    local list = M.head
    while list.next.value ~= index do
      list = list.next
      break
    end
    list.next = list.next.next
  end
  M.tail.next = {next = nil, value = index}
  M.tail = M.tail.next
  if M.unused == nil then
    M.unused = M.tail
  end
end

function M.print()
  local list = M.head
  while list do
    list = list.next
  end
end

function M.add_keyword(word)
  word = word or ("<" .. vim.fn.expand("<cword>") .. ">")
  local index
  if M.unused then
    index = M.unused.value
    M.unused = M.unused.next
  else
    index = M.head.value
    M.head = M.head.next
    -- place its to last
    M.tail.next = {next = nil, value = index}
    M.tail = M.tail.next
  end
  M.keywords[index] = word
  M.selected = index
end

-- return 0 for false, other value for keyword index
function M.is_keyword(word)
  word = word or ("<" .. vim.fn.expand("<cword>") .. ">")
  for i, kw in ipairs(M.keywords) do
    if kw == word then
      return i
    end
  end
  return 0
end
-- if cursor is on a marked word, return this word
-- else return last used keywords
function M.get_current_keyword()
  local index = M.is_keyword()
  if index == 0 then
    if M.selected == 0 then
      return ""
    else
      return M.keywords[M.selected]
    end
  else
    M.selected = index
    return M.keywords[index]
  end
end

function M.get_all_keywords()
  local t = {}
  for _, kw in ipairs(M.keywords) do
    if kw and kw ~= "" then
      table.insert(t, kw)
    end
  end
  if #t ~= 0 then
    return '(' .. table.concat(t, '|') .. ')'
  end
end

return M
