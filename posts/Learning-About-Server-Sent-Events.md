---
Date: 03/31/2025
Summary: "This post is a quick, hands-on intro to Server-Sent Events (SSE)—a lightweight way to push real-time updates from server to browser. It walks through sending events with Go, listening in JavaScript, handling custom events, and tweaking reconnection settings. If you want simple, one-way live updates without the overhead of WebSockets, SSE might be your new best friend."
Author: Kenton Vizdos
Tags: JavaScript, Go
---

## What led me to SSE

Over the past few projects I've done, I've wanted a way of adding some basic real-time UI updates (think like in-app Notifications). "Traditionally," I would lean for WebSockets, but something just really felt odd using a full `ws` connection for only sending events from the server.

Wait!

"Sending events from the server".. hmm.. Server Sent Events to the rescue!

## What is a Server Sent Event (SSE)?

They are *similar* to WebSockets, as they let the server communicate with the frontend. But that's about it. The client **cannot** communicate with the server.

Some other pitfalls include:

- Text only encoding: no binary formats :<
- Some old proxies have trouble routing SSEs
- Over HTTP/1, only 6 connections can be established per client browser. On HTTP/2, it defaults to 100, but can be modified. Do note: for HTTP/1 support, check out Shared Workers or `Web Locks` (i've never heard about those until now.. they are pretty slick)

For my use case, these will work okay. I'm down to risk the "old proxy" mess until it happens..

## How do you send an SSE?

This is one of the beauties. It is SO simple, here is a (highly barebones) example. The following code will send "data: hello!" ever 100ms:

```go
mux.HandleFunc("GET /sse", func(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")

	for {
		fmt.Fprintf(w, "data: hello!\n\n")
		w.(http.Flusher).Flush()
		time.Sleep(100 * time.Millisecond)
	}
})
```

Some important parts to note:

- Content type is required to be `text/event-stream`
- Connection needs to be kept to `keep-alive`

Another reason to love Go (i'm sure this exists in other langs), the connection can be detected as closed nearly instantly:

```go
for {
	select {
		case <-time.After(100 * time.Millisecond):
			fmt.Fprintf(w, "data: hello!\n\n")
			w.(http.Flusher).Flush()
		case <-r.Context().Done():
			log.Println("Connection closed!")
			return
	}
}
```

Before we dig into `event types`, let's check out how easy it is to connect this into JS.

## Listening to SSE in JS

Okay, when you need to listen, the simplicity remains:

```js
const sseSource = new EventSource("/sse");

sseSource.onopen = (e) => {
  console.log("The connection has been established, ready for events.");
};

sseSource.onmessage = (event) => {
	console.log(event.data)
};

sseSource.onerror = (err) => {
  console.error("sseSource:", err); // This will automatically try to reconnect, amazing!
};
```

Yup, thats pretty much it! However, we can get even fancier.

Note: If you need to send a cross-URL request with cookies, use:

```js
const sseSource = new EventSource("/sse", {
  withCredentials: true,
});
```

## Custom Events in SSE

While sure, you could always encode an event type in the `data:` field, it's unnecessary!

There is an `event:` field in SSE that will be completely hookable in JS. For this demo, we'll specify an `example_event`:

```go
for {
	select {
		case <-time.After(100 * time.Millisecond):
			fmt.Fprintf(w, "event: example_event\ndata: hello, custom event!\n\n") // the \n\n is incredibly important, that is the delimiter for events!
			w.(http.Flusher).Flush()
		case <-r.Context().Done():
			log.Println("Connection closed!")
			return
	}
}
```

In JavaScript, we can hook into it with:

```js
sseSource.addEventListener("example_event", (event) => {
  console.log("Example Event Data:", event.data);
});
```

And bam! We can now *just* receive those individual events.

**Good to know:** The `onmessage` event still fires for any event that DOES NOT specify an `event:`

## Specifying Reconnection Settings

Reconnection settings can be modified with `retry:`. Specified in milliseconds, this field lets you configure how long to wait until a reconnection is tried. (remember to flush this event, heh)

## Going Forward

Sure, you'll still need state management on the server side (and probably a Pub/Sub provider for horizontally scaled services), but in my opinion, it's definitely worth it! There are also packages and the like to make this easier.

Enjoy working with SSEs, they are well supported (minus IE + Opera Mini) and very simple.
