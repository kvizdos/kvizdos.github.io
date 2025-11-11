---
Date: 11/11/2025
Summary: "The easiest way to steal a single file from another branch."
Author: Kenton Vizdos
Tags: Git, Guides
---

## The Problem

In my project, I have a set of prechecks that run prior to an action taking place. I made some adjustments to a specific precheck within a branch, but I needed to pull that update into main without merging the entire branch.

## How to Copy a Single File from Another Branch

...without merging, like a Pro.

```bash
git restore --source <branch_name> -- <file_path>
```

That's literally it. I don't know why it took me so long to figure this one out.
