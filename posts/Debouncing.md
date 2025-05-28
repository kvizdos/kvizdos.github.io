---
Date: 05/27/2025
Summary: "A practical look at how modern search inputs use debouncing and AbortControllers to feel fast without wasting resources. Includes real examples and tips for building your own."
Title: Real-Time Search Doesn't Mean Real-Time Requests
Author: Kenton Vizdos
Tags: UX, Optimization, Performance
---

## Why Real-Time Feels Slow

Have you ever searched *anything* in "real-time"?

Humans type fast (sometimes).

Sending a request on every keystroke is wasteful, slow, and costly. Developers need a solution that **feels responsive** yet intelligently waits until the user pauses.

Introducing... debouncing & aborts.

## What Is Debouncing?

Debouncing is the solution to many developers' problems. Commonly used in real-time search fields, debouncing prevents sending tens of requests per query. Debouncing accomplishes this by measuring the time between keystrokes and only "officially" sending a request after ~200-400ms have passed.

Without debouncing, a network may look like:
- **User types: "t"**: `GET /api/search?q=t`
- **User types: "te"**: `GET /api/search?q=te`
- **User types: "tes"**: `GET /api/search?q=tes`
- **User types: "test"**: `GET /api/search?q=test`

On the other hand, if the search was debounced and the user types quickly:
- **User types: "test"**: `GET /api/search?q=test`

Since the user typed "test" with less than 200ms between each keystroke, the debounce timer kept resetting. Only after typing stopped for 100ms did the final request fire, saving three unnecessary fetches.

Debounce comes in three distinct flavors, each tuned to when you want the callback to fire:

- **Trailing Edge:** The action is completed AFTER the delay.
- **Leading Edge:** The action is completed BEFORE the delay.
- **Both:** Complete it after & before the delay.

In the wild, I found a few companies where debouncing quietly saves bandwidth:

- **GitHub Search:** Instead of sending a fetch for every keydown event, they debounce it to combine results (they also cache responses within JS memory space; **not** the network level).
- **ebay:** Similar to GitHub, they do JS-caching and autofill results from a local cache.

While debouncing can provide a robust solution for many search solutions, Abort Signals provide an extra layer to beef up performance.

## What Is an Abort Signal?

As of March 2019, all major browsers can now cancel `fetch()` requests. (wow, that took a while! [IE + Opera Mini not included](https://caniuse.com/abortcontroller))

This means that, combined with debouncing, servers can reduce load and prematurely cancel old requests as soon as a new query comes in. In Go, this is as simple as passing the `request.Context()` into your database driver of choice: the request-- propagating all the way to the database-- is canceled instantly. No more wasted ops, woot!

A few real-life use cases of pure abort signals include:
- **Google Search:** Google keeps 4 requests in flight; any older requests are aborted.
- **Google Maps:** Only 1 request in flight at a time

Some places don't do either!

- **YouTube & Amazon:** No debouncing or aborts.

## UX Benefits

Users feel instant feedback without burning bandwidth. Primarily, they can interact with systems that "feel" real-time, yet consider their network usage / CPU time. These techniques also help to reduce "flickering" that could occur when multiple requests come back at once (search YouTube on a slow connection, eesh!).

Both debouncing & aborts can make use of heavy client-side caching to provide a seamless search experience.

## When to use Debouncing & Aborts

While I've gone on to talk about search so far, debouncing also has a few other nice use cases:

- **Event Handling:** Let's say you need to send a request any time the window is resized... instead of sending 10,000 requests for every pixel change, you can debounce the event handler to say: "Only send a request once there has been no resize event for 200ms."
- **Rage Click Prevention:** If you have a clickable button, debounce the "click" event to ensure that multiple simultaneous clicks only do an action once (leading edge).
- **Really any event**: Debouncing is incredibly helpful any time you have an interaction-dispatched event handler.

Aborts, on the other hand, are usually used with events involving network calls (e.g. `fetch()`).

## How I'd design a Search System

I don't run billion-dollar companies. I'd rather not be like YouTube and Amazon and query every search: that sounds pricey. After researching how a few sites do it, I think my approach would be:

- **Debounce user input at 100ms:** this seems to comfortably reduce network IO for fast typers, while not overloading downstream systems.
- **Only allow 1 request in flight:** I'd abort any requests that are currently in flight once a new query is sent. Occasionally, this may cause a few hundred milliseconds of "empty" results, but I think it can be managed.
- **Utilize a memory cache:** I really liked this piece of ebay & GitHub: it made the search feel blazing, even on slow networks. Once a query is resolved, I'd cache the query + results. If a user begins to search for a new query, I'll look up to see if we have any cached queries that start with the current query, and then filter those results.

I may allow more than 1 request in flight. If I did it, I'd need to pay extra attention to making sure the latest request accurately resolved in the search.

Next post that actually *implements* this coming soon!
