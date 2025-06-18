local function class()
  local cls = {}
  cls.__index = cls
  function cls:new(...)
    local instance = setmetatable({}, cls)
    if instance.init then
      instance:init(...)
    end
    return instance
  end
  return cls
end

local function is_positive(n)
  return n > 0
end

local function compare(a, b, op)
  if op == "equal" then
    return math.abs(a - b) < 1e-12
  elseif op == "greater" then
    return a > b
  elseif op == "less" then
    return a < b
  else
    return false
  end
end

local function parse_check(name, var_value)
  local op, val_str = name:match("^(%a+)_([%d%.%-]+)$")
  local val = tonumber(val_str)
  if not op or not val then
    return function() return false end
  end
  return function()
    return compare(var_value, val, op)
  end
end

local Operator = class()

function Operator:init(name, action_func, var_value)
  self.name = name
  self.check = parse_check(name, var_value)
  self.action = action_func
  self.result = nil
end

function Operator:run_async()
  return coroutine.create(function()
    while true do
      if self.check() then
        self.result = self.action()
        return
      end
      coroutine.yield()
    end
  end)
end

local OperatorSystem = class()

function OperatorSystem:init(var_value)
  self.var_value = var_value
  self.ops = {}
  self.else_action = nil
end

function OperatorSystem:add_operator(name, action_func)
  table.insert(self.ops, Operator:new(name, action_func, self.var_value))
end

function OperatorSystem:set_else(action_func)
  self.else_action = action_func
end

function OperatorSystem:run_async()
  local threads = {}
  for _, op in ipairs(self.ops) do
    table.insert(threads, {
      coroutine = op:run_async(),
      operator = op,
      done = false
    })
  end
  while true do
    local any_active = false
    for _, thread in ipairs(threads) do
      if not thread.done then
        local ok = coroutine.resume(thread.coroutine)
        if coroutine.status(thread.coroutine) == "dead" then
          thread.done = true
        end
        if thread.operator.result ~= nil then
          return thread.operator.result
        end
        any_active = true
      end
    end
    if not any_active then
      break
    end
  end
  if self.else_action then
    return self.else_action()
  end
  return nil
end

return {
  OperatorSystem = OperatorSystem
}
