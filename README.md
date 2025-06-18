# IfEmu

IfEmu is a conditional logic emulator for Lua that **avoids using the built-in `if` statement**. Instead, it simulates `if-elseif-else` structures through class-based design, coroutine-based evaluation, and dynamic string-parsed conditions.

The project is inspired by the idea of controlling flow without relying on traditional syntax, enabling experimentation with flexible and modular logic evaluation in a completely programmable way.

IfEmu is ideal for advanced Lua users exploring architecture without hardcoded conditions or who want logic that's entirely runtime-driven.

## Features

- Asynchronous-style logic emulation
- Conditions parsed from string patterns (`greater_5`, `less_10`, `equal_3`, etc.)
- Flexible and runtime-modifiable logic
- Simple API to register conditional branches
- Fully avoids `if`, `then`, `elseif`, `else`

# How It Works?

The emulator is built around three main components:

1. **`OperatorSystem` class** – the interface to register conditions using `add_operator()` and define fallback behavior via `set_else()`.

2. **`Operator` class** – represents each condition with a name like `greater_20`, a testable value, and an action function. Each is evaluated asynchronously using a coroutine.

3. **`compare` and `parse_check` functions** – convert string-based conditions into numeric comparisons using math logic (instead of `if`) and precision-safe equality checks.

All operators run in parallel using coroutines. The first successful condition returns its result. If none match, the fallback action is used instead.

---

Example usage:

```lua
local x = 10

local sys = OperatorSystem:new(x)

local result = (sys
  :add_operator("greater_20", function() return "x > 20" end)
  :add_operator("greater_5", function() return "x > 5" end)
  :set_else(function() return "x <= 5" end)
):run_async()

print(result)  -- x > 5
