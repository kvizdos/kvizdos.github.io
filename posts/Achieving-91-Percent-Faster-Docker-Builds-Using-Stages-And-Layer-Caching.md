---
Date: 03/18/2025
Summary: "I Cut Docker BuildX Times from 9 Minutes to 45 Seconds using better Layer Caching and Multi-Stage builds."
Author: Kenton Vizdos
Tags: Docker, Thinking Out Loud
---

## The Problem

I use (what I thought were decent) Docker Multi-Stage builds to keep image sizes down, but I still had a massive problem: **my (buildx cross compilation) builds took 9 minutes!** What I didn't realize is that I wasn't entirely knowledgeable on 2 core Docker optimizations:

- **Layer Caching:** I was invalidating my cache way too often, making unnecessary rebuilds.
- **Parallelization:** Docker automatically runs independent stages in parallel, but I wasn't structuring my builds to take advantage of it.

Once I optimized both of these, my (buildx cross compilation) build time **dropped from 540 seconds to just 45**, a 91% speedup!

For context, this is what my Dockerfile looked like in the beginning:

```dockerfile
FROM golang:1.24 AS build-env

ARG BUILD_VERSION
ARG BUILD_DATE
ARG BUILD_COMMIT
ARG BUILD_TAGS
ARG GOARCH
ARG GOOS

WORKDIR /app

COPY . ./

RUN apt-get update && apt-get install -y tzdata nodejs npm

# Install go dependencies
RUN go mod download

RUN npm install -g typescript

# Navigate to admin directory, install dependencies, and build the app
WORKDIR /app/internal/frontend/admin
RUN npm ci
RUN npm run build

# Navigate to user directory, install dependencies, and build the app
WORKDIR /app/internal/frontend/user
RUN npm ci
RUN npm run build

# Return to the main app directory
WORKDIR /app

RUN CGO_ENABLED=0 GOARCH=${GOARCH} GOOS=${GOOS} go build \
    -o kitchensink \
    ./cmd/kitchensink/main.go

# Final Stage (make the image smaller w/ multistages)
FROM scratch

WORKDIR /

COPY --from=build-env /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build-env /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=build-env /app/kitchensink /kitchensink

ENV TZ=UTC

ENTRYPOINT ["./kitchensink"]
```

## Step 1. Understand Caching

Docker heavily utilizes `layer caches` to make builds faster. The system creates a new `layer` for every **instruction** (e.g. `RUN`, `COPY`, etc), and can intelligently cache, meaning if a step hasn't changed, Docker reuses the cached result instead of re-running it.

However, improper layer ordering can break caching and force unnecessary rebuilds. A mistake I've turned into a habit is placing `COPY . ./` too early in the Dockerfile. Since this copies every single file, **any file change invalidates the cache for all subsequent layers**, even those that don't depend on the changed file.

This was a big issue, considering that whenever any of my code changed, I was invalidating every layer; not just what changed.

A basic fix to this is modifying the `COPY` instructions to be more direct, such as:

```dockerfile
FROM golang:1.24 AS build-env

# args
# REMOVE COPY from here
# everything remains the same

WORKDIR /app/internal/frontend/admin

COPY ./internal/frontend/admin/package.json ./
COPY ./internal/frontend/admin/package-lock.json ./

RUN npm ci

WORKDIR /app/internal/frontend/user

COPY ./internal/frontend/user/package.json ./
COPY ./internal/frontend/user/package-lock.json ./
RUN npm ci
```

Just from this one change, layer caching has improved in such a way that `npm ci` will only do a full install when the `package.json` / lockfile changes. Otherwise, it can continue on to build, saving valuable time and bandwidth. This idea of using `COPY` just on the files you're working with repeats in later steps. It is a major discovery to me (facepalm).

While this is an immediate WIN in caching, what happens if both packages need updating? Currently, they will run sequentially one after the next. This can be... slow.

## Step 2. The Power of Multi-Stage Builds

What I never realized, somehow, is that Docker Multi-Stage builds will run in parallel!

The best part? You don't even need to really think about the "parallel"-ness; Docker will take care of keeping track of which parts need to wait on what.

The next optimize I did was to create two stages for the installation process so that they can run at the same time:

```dockerfile
# Install Admin Node Dependencies
FROM --platform=$BUILDPLATFORM node:lts-alpine AS admin-deps-install

WORKDIR /admin-deps
COPY /internal/frontend/admin/package.json ./
COPY /internal/frontend/admin/package-lock.json ./

RUN npm ci

# Install User Node Dependencies
FROM --platform=$BUILDPLATFORM node:lts-alpine AS user-deps-install

WORKDIR /user-deps

COPY /internal/frontend/user/package.json ./
COPY /internal/frontend/user/package-lock.json ./

RUN npm ci
```

[Curious about that --platform piece? I spent about 2 hours debugging that..](/post/How-to-fix-Docker-BuildX-lfstack-push-Error)

## Step 3. Inherit Stages

In my Dockerfile, I've now solved the issue of running both installs only when necessary; however, the same thing happens for the build step.

Referencing the original Dockerfile, you can see I installed `typescript` globally before doing any of this work:

```dockerfile
RUN npm install -g typescript

# Navigate to admin directory, install dependencies, and build the app
WORKDIR /app/internal/frontend/admin
RUN npm ci
RUN npm run build

# Navigate to user directory, install dependencies, and build the app
WORKDIR /app/internal/frontend/user
RUN npm ci
RUN npm run build
```

Since this, and other pre-build dependencies, needs to be installed prior to building, I decided to create a base `builder` image:

```dockerfile
FROM --platform=$BUILDPLATFORM node:lts-alpine AS node-builder

RUN npm install -g typescript
RUN npm install -g rimraf
```

Now, instead of rerunning the same code twice for each UI, I can simply inherit this base image:

```dockerfile
# Build Admin UI
FROM node-builder AS admin-builder

WORKDIR /app

COPY ./internal/frontend/admin/ .
COPY --from=admin-deps-install /admin-deps/node_modules ./node_modules

RUN npm run build

# Build User UI
FROM node-builder AS user-builder

WORKDIR /app

COPY ./internal/frontend/user/ .
COPY --from=user-deps-install /user-deps/node_modules ./node_modules

RUN npm run build
```

Note here how I'm only ever copying the frontend code and dependencies: nothing else. This loops back again to the idea of layer caching.

With this setup, both builds will run in parallel, saving a "massive" amount of time (roughly 1-3 minutes). The sweetness really comes from the layer caching, though: these stages will only build what is *necessary* (changed since last time) in the moment. No more waiting to do the same thing every build!

## Step 4. Pulling it all Together

Since my backend, and the piece that serves the frontend, is in Go, I need to move the built files into a `golang` env builder. This is really simple using the `COPY --from=<stage>` command.

You will also see how I reiterated the learning of "only pull in necessary files" with the `go mod download` command.

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.24 AS build-env

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . ./

COPY --from=admin-builder /app/dist /app/internal/frontend/admin/dist
COPY --from=user-builder /app/dist /app/internal/frontend/user/dist

# finally build, rest of file identical.
```

## Conclusion

By reordering `COPY` instructions, splitting dependencies into separate stages, leveraging parallel multi-stage builds, and minimizing unnecessary rebuilds, I reduced post-first `buildx` build times from 540 seconds to just 45 seconds: **a 91% improvement.**

![](/assets/blog/91-percent.webp)
Screenshot showing final build time of 47.5 seconds.

These optimizations not only speed up development but also reduce resource usage and network overhead, making iteration cycles significantly smoother. More importantly, they create a scalable and maintainable build process that efficiently handles changes without redundant work.

If you're struggling with long Docker build times, try applying these techniques. As I've learned, small changes in Dockerfile design can lead to massive improvements in performance.

### Challenges and Learnings

- `docker buildx` has some weird behaviors. A real challenge was finding out I needed to specify the `--platform` tag in `FROM` instructions. [The error I was getting was quite odd, and nearly un-Google-able](/post/How-to-fix-Docker-BuildX-lfstack-push-Error). I'm honestly not quite sure why the first Dockerfile worked.
- Keep `COPY . ./` minimal and exact: never do this until you absolutely need to.
- Layer Caching Waterfalls: when one layers cache invalidates, all downstream layers are invalidated.
- Reduce redundant installs by inheriting base stages.
- Use parallel multi-stage builds for dependencies.
