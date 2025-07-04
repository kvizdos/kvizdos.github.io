---
Date: 07/05/2025
Summary: "Learn how to organize Go HTTP routes using nested muxes, StripPrefix, and modular patterns. Transform messy flat routing into clean, scalable APIs using only the standard library - no third-party packages needed."
Author: Kenton Vizdos
Tags: Go, Guides
Title: Routing Patterns in Go Stdlib
---

## Modern Approaches to Routing

Nowadays, Go developers can stay in the standard library for quite a while. There's no real need to reach for a third-party router (Chi, FastHTTP, Gorilla Mux, etc) unless you're backed by a strong technical reason like zero allocations or tight latency budgets.

[In the previous post, we saw how basic routing works but ran into organizational challenges](/post/go-mux). As a reminder of what the endpoints looked like:

```go
func main() {
	http.HandleFunc("GET /api/users", usersHandler)
	http.HandleFunc("GET /api/users/{id}", userHandler)
	http.HandleFunc("GET /api/posts", postsHandler)
	http.HandleFunc("GET /api/posts/{id}", postHandler)
	// ...
}
```

Since most of these share a common prefix, we can, and should, start to group our endpoints:

```go
func RouteAPI() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /users", usersHandler)
	mux.HandleFunc("GET /users/{id}", userHandler)
	mux.HandleFunc("GET /posts", postsHandler)
	mux.HandleFunc("GET /posts/{id}", postHandler)
	return mux
}

func main() {
	http.Handle("/api/", http.StripPrefix("/api", RouteAPI()))
	// ...
}
```

With this general flow in mind, we can begin to see how this scaffolds. The API routes are now organized and only accessible via `/api/`, however we can still see logical grouping happening within the RouteAPI() function. Let's take this one step further...

```go
func RouteUsers() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /", usersHandler)
	mux.HandleFunc("GET /{id}", userHandler)
	return mux
}

func RoutePosts() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /", postsHandler)
	mux.HandleFunc("GET /{id}", postHandler)
	return mux
}

func RouteAPI() *http.ServeMux {
	mux := http.NewServeMux()
	mux.Handle("/users/", http.StripPrefix("/users", RouteUsers()))
	mux.Handle("/posts/", http.StripPrefix("/posts", RoutePosts()))
	return mux
}

func main() {
	http.Handle("/api/", http.StripPrefix("/api", RouteAPI()))
	// ...
}
```

This modular approach scales naturally, and it's all in the stdlib.

## What Is http.StripPrefix?

In the code above, I slipped in this critical bit of code to manage the routing:

```go
http.Handle("/api/", http.StripPrefix("/api", RouteAPI()))
```

But... what the heck is `StripPrefix` actually doing?

Think of it like a middleman that chops off part of the URL path before handing it off to the next mux or handler.

### Example:

If a request comes in for `/api/users`, and we've done this:

```go
http.Handle("/api/", http.StripPrefix("/api", someHandler))
```

Then `someHandler` will see the request as `/users`. It doesn't know (or care) that it used to start with `/api`:

```go
// A request comes into /api/users...
http.Handle("/api/", http.StripPrefix("/api", someHandler))
// someHandler now gets a request with the path set to `/users`
```

This makes it possible to compose handlers cleanly and nest routing logic without each inner mux needing to know its full path.

You might've noticed only the first argument in `StripPrefix` has a trailing slash: that's intentional, and required:

```go
http.Handle("/api/", http.StripPrefix("/api", someHandler))
```

This is critical so that, once passed to the handler, the "new path" will begin with a slash.

## Trailing Slashes Matter

That trailing `/` in `/api/` or `/users/`? Yeah, it's not just stylistic sadly.

In `http.ServeMux`, **only paths that end in a slash are treated as prefix matches**. This means:

```go
// Matches /api/* — GOOD
// GET /api/test WILL resolve
mux.Handle("/api/", handler)

 // Only matches /api exactly — probably BAD
 // GET /api/test WILL NOT resolve
mux.Handle("/api", handler)
```

So if you want your handler or sub-mux to respond to everything under `/api`, you need the slash.

These little things: StripPrefix, trailing slashes might seem nitpicky, but they're what let muxes scale cleanly. Once you get a feel for them, muxing in Go is dead simple.

## Stdlib has your back

With these patterns, you can build production-ready APIs that stay organized as they grow, all without leaving the standard library. The combination of nested muxes, StripPrefix, and careful attention to trailing slashes gives you everything you need for clean, scalable routing.

No third-party dependencies required.
