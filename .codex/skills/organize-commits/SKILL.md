---
name: organize-commits
description: Stage and commit Git changes hunk by hunk, or redo an explicitly selected range of existing commits from an unstaged working tree. Use in any repository when asked to organize or create commits.
---

# Organize commits

This is a global skill. Use it in any Git repository, but operate only on the repository containing the current directory unless the user explicitly names another one.

## Current changes

1. Read the current branch and status, then inspect the staged diff, unstaged diff, and relevant untracked files. Review every changed hunk, including files with staged changes. A file or one hunk can contain changes for different purposes.
2. Group changes into focused commits by behavior and dependency. Stage the hunks for one commit at a time. Rearrange already staged hunks when necessary using partial staging or index-only patches. Preserve unrelated work and the working tree. Review each staged diff before committing.
3. The user has given standing authorization to stage and create commits across repositories. Run `git add`, `git commit`, read-only Git inspection, and index-only operations needed to organize commits without requesting separate confirmation for each command or commit. Review each staged diff before committing. Do not push or rewrite existing history without explicit authorization. Respect enforced sandbox approvals.

## Existing commits

Require the user to select the commits to redo, for example “reorganize the last 4 commits” or “reorganize from `abc1234` through `HEAD`, inclusive.” Do not guess a range from the branch history. The selected commits must be a contiguous range ending at `HEAD`; if they are not, ask which contiguous tip range to use before changing history.

Inspect the selected commits and current index/worktree, identify the parent of the oldest selected commit, and check whether the commits have been published. Explain the exact reset target and ask permission for the history rewrite. Do not rewrite published history without explicit authorization.

After permission, start the reorganization with `git reset --mixed <parent-of-oldest-selected-commit>`. This removes the selected commits from the branch and unstages everything while preserving their changes and any existing staged or unstaged work in the working tree. Then follow **Current changes** from its first step, staging and committing the selected changes hunk by hunk. Never use `--hard` for this workflow.

## Commit messages and reporting

For a branch containing one Jira issue ID such as `DC-1095`, format each subject as `DC-1095 [feat]: Add health record drafts` or `DC-1095 [fix]: Correct consent lookup`. Use the branch's actual issue ID and a suitable type (`feat`, `fix`, `refactor`, `chore`, `docs`, etc.). Without a Jira issue ID, use `feat: Add health record drafts` style. Ask if a branch contains multiple plausible IDs.

Report the created commit hashes and subjects, plus any changes left uncommitted.

Do not run tests, typecheck, lint, build, a dev server, Playwright, simulators, emulators, app launches, or other verification commands unless the user explicitly asks. Git inspection needed to prepare and review commits is allowed.
