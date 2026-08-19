# Coding write

**Default: create after answering.** The server extracts facts and dedups against history, so passing the raw turns is enough.

```
create_memory(
  domain="coding",
  session_id="<repo-name>",
  memory_hint="convention",  # optional
  messages=[2–4 recent user/assistant turns],
)
```

## Skip create (narrow only)

- **Unverified guess** — you summarized without reading the code
- **Transient debug state** — "breakpoint currently at L42", "server is running on port 3000 right now"
- **Typo / single-line format / pure one-off patch** with no reusable content
- Nothing new vs. what you just searched (true duplicate)

Everything else → create. Do not hold back because "the user didn't say 请记住" or "AGENTS.md might cover this".

## memory_hint (optional)

A typing hint for the memory. Pick the closest fit:

| Type | Signal | Example |
|------|--------|---------|
| `convention` | Module/arch map, data flow, project habit | "记忆模块在 app/memory_management" |
| `decision` | Choice closed, implementation done | "就这样用 FastAPI" |
| `constraint` | User forbids an approach | "别用全局单例" |
| `correction` | Fixes a recurring agent mistake | "我们用的是 JWT 不是 cookie" |
| `lesson` | Debugging closed | "502 是端口没对齐" |
| `preference` | Repeated habit | "解释用中文" |

`memory_hint` is an agent-side hint; the MCP server may not persist it to the Engine today. Omit it if unsure.