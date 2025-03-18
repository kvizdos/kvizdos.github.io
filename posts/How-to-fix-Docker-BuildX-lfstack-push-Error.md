---
Date: 03/17/2025
Summary: "Encountering the fatal error: lfstack.push when cross-compiling Docker images with buildx? This issue happens when the base image lacks the correct platform setting, leading to runtime failures."
Author: Kenton Vizdos
Tags: Docker, Hotfix
---

## When does this issue happen?

When you build a Docker image with `buildx` for cross-compilation (e.g. M series Mac to AMD64), you may see the error:

```bash
fatal error: lfstack.push

runtime stack:
runtime.throw({0x9b2656?, 0x100000000000000?})
	runtime/panic.go:1047 +0x5d fp=0xffff9d386638 sp=0xffff9d386608 pc=0x4357dd
runtime.(*lfstack).push(0x2?, 0xffff9d3866e8?)
	runtime/lfstack.go:29 +0x125 fp=0xffff9d386678 sp=0xffff9d386638 pc=0x40b4c5
runtime.(*spanSetBlockAlloc).free(...)
	runtime/mspanset.go:322
runtime.(*spanSet).reset(0xd54ed0)
	runtime/mspanset.go:264 +0x87 fp=0xffff9d3866a8 sp=0xffff9d386678 pc=0x42f747
runtime.finishsweep_m()
	runtime/mgcsweep.go:260 +0x9c fp=0xffff9d3866e8 sp=0xffff9d3866a8 pc=0x42377c
runtime.gcStart.func1()
	runtime/mgc.go:668 +0x17 fp=0xffff9d3866f8 sp=0xffff9d3866e8 pc=0x463397
runtime.systemstack()
	runtime/asm_amd64.s:496 +0x49 fp=0xffff9d386700 sp=0xffff9d3866f8 pc=0x467dc9
```

## Why does this issue happen?

This issue occurs because the image you imported using a `FROM` does not have the correct platform set. It's really weird that Docker doesn't do this for you, but the fix is easy.

## Fixing fatal error: lfstack.push is simple.

Each time you use `FROM`, be sure to include `--platform=$BUILDPLATFORM`. Docker automatically sets the environment variable, so no need to worry about setting things manually.

Full code example:

```dockerfile
FROM --platform=$BUILDPLATFORM node:lts-alpine AS node-builder
```

Note: You should set this on **every** Docker stage; not just a builder / dependency install stage.
