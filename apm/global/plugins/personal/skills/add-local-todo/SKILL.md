---
name: add-local-todo
description: Add a concise task note to the current repository's existing .local/TODO.md when explicitly asked to capture something for later.
---

# Add local TODO

On explicit invocation, turn the user's request or immediately relevant conversation context into one actionable TODO item. Use plain, caveman-style fragments: specific action first, minimal words, no filler. Keep technical names exact. Use the relevant repo context to avoid vague reminders or invented requirements.

Find the current repository root. Check whether `<repo>/.local/TODO.md` is an existing regular file. If yes, read it and append one Markdown bullet that fits its format; avoid duplicating an existing item. Preserve all other content. Do not create the file or its parent directory.

If the file does not exist, print the proposed bullet and say `.local/TODO.md` does not exist in this repository. Do not write elsewhere. If the current directory is not in a repository, print the proposed bullet and say no repository root was found.

Report the added item or the proposed item in the final response, concisely.
