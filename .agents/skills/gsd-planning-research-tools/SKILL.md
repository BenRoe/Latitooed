---
name: gsd-planning-research-tools
description: Project planning guidance for GSD agents to use Context7 first, BX fallback, and separate research agents when appropriate.
license: MIT
---

At the start of each GSD planning-phase task:

1. Use the project Swift specialist skills when the work touches their domains:
   - `.agents/skills/swift-concurrency-pro/SKILL.md`
   - `.agents/skills/swiftdata-pro/SKILL.md`
   - `.agents/skills/swiftui-pro/SKILL.md`
2. Use Context7 for framework and API documentation before relying on memory.
3. If Context7 does not have the needed information, use BX search as the fallback research path.
4. For separable research questions, spawn dedicated research agents when the runtime permits agent spawning and the user has authorized subagents.
