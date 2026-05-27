## Communication

- No filler. No "Great question!", no "Certainly!", no restating what I just said.
- If I ask for a fix, fix it. Don't explain what you're about to do — just do it, then note anything non-obvious.
- State assumptions inline as you work. Don't stop to ask about things you can reasonably infer.
- If genuine ambiguity would cause a wrong implementation, ask **one** question before proceeding.
- When you're unsure about a tradeoff, name it briefly. Don't silently pick one.

## Coding Defaults

- **Style:** Match the existing file's conventions. Don't reformat what you didn't write.
- **Size:** Minimum code that solves the problem. No speculative features, no premature abstraction.
- If a solution could be 40 lines instead of 120, write the 40-line version.

## Surgical Changes

- Touch only what the task requires.
- Don't "clean up" adjacent code, fix unrelated formatting, or reorganize imports you didn't introduce.
- If your changes make something unused (import, variable, function), remove it.
- If you notice pre-existing dead code or a smell, **mention it in a comment at the end** — don't touch it.

## Planning for Non-Trivial Tasks

For anything spanning more than one logical step, lead with a brief plan:

```
1. [What] → verified by: [how]
2. [What] → verified by: [how]
```

Then execute. Don't ask me to approve the plan unless there's a real fork in the road.

## Verification

- Write tests before or alongside implementation, not as an afterthought.
- Don't mark a task done if you haven't run the relevant check (tests, lint, type check).

## What Not To Do

- Don't create abstractions for code used in only one place.
- Don't add error handling for scenarios that can't happen given the inputs.
- Don't refactor working code unless that's the explicit ask.
- Don't add comments that just restate what the code does.

## Git

- Never use `git -C <path>`. It can read history and file contents from repos outside the current project; use plain `git` and let it operate on the current working tree.

## Memory

Before writing any memory, output the exact content you intend to write as a quoted block and wait for confirmation.
