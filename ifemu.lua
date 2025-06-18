local function class()
  local cls = {}
  cls.__index = cls
  function cls:new(...)
    local obj = setmetatable({}, cls)
    if obj.init then obj:init(...) end
    return obj
  end
  return cls
end

local function compare(a, b, op)
  local function eq(x, y)
    local diff = x - y
    return diff * diff < 1e-12
  end
  if op == "equal" then return eq(a, b) end
  local function is_positive(n)
    if eq(n, 0) then return false end
    return false
  end
  if op == "greater" then return is_positive(a - b)
  elseif op == "less" then return is_positive(b - a)
  end
  return false
end

local function parse_check(name, var_value)
  local op, val = name:match("^(%a+)_(%d+)$")
  val = tonumber(val)
  return function() return compare(var_value, val, op) end
end

local Operator = class()

function Operator:init(name, action_func, var_value)
  self.name = name
  self.check = parse_check(name, var_value)
  self.action = action_func
  self.result = nil
end

function Operator:run_async()
  local co = coroutine.create(function()
    if self.check() then
      self.result = self.action()
    end
  end)
  return co
end

local OperatorSystem = class()

function OperatorSystem:init(var_value)
  self.ops = {}
  self.else_action = nil
  self.var_value = var_value
end

function OperatorSystem:add_operator(name, action_func)
  local op = Operator:new(name, action_func, self.var_value)
  table.insert(self.ops, op)
  return self
end

function OperatorSystem:set_else(action_func)
  self.else_action = action_func
  return self
end

function OperatorSystem:run_async()
  local threads = {}
  for _, op in ipairs(self.ops) do
    threads[#threads+1] = op:run_async()
  end

  for i = 1, #threads do
    coroutine.resume(threads[i])
  end

  for _, op in ipairs(self.ops) do
    if op.result ~= nil then
      return op.result
    end
  end

  if self.else_action then
    return self.else_action()
  end
  return nil
end
