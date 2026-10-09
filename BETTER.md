# Making kv.codes better

Notes from a pass over this repo and the live site on 2026-10-09. Ordered roughly by payoff per hour of effort.

---

## 1. Quick SEO fixes (an afternoon)

### Homepage meta is off — `templates/index.html`
- `og:title` is `README.md - Kenton Vizdos`. That's what shows up when someone shares kv.codes on LinkedIn/Bluesky/Slack. Change to `Kenton Vizdos — Development Log` (or similar).
- `og:image` is relative (`/assets/about/og.png`). Most scrapers require absolute URLs → `https://kv.codes/assets/about/og.png`.
- No `og:url`, `og:description`, or `og:type`. Add them.
- `<meta name="description">` is "Blog related to all things programming." — generic, and it's the snippet Google shows. Write something specific: *"Kenton Vizdos writes about Go, backend performance, security, and accessible UI — from someone building software for K–12 education."*

### No canonical URLs anywhere
Both `https://kv.codes/post/Debouncing` and `https://kv.codes/post/Debouncing.html` return 200. Google sees two copies of every post. Add to `post.html`, `tag.html`, `index.html`, and each static page:

```html
<link rel="canonical" href="https://kv.codes/post/{{ .Slug }}" />
```

(Use whatever the template variable for the URL is; add one to easyblog if there isn't one.) Also add `og:url` to `post.html` — it's on tag/static pages but missing from posts.

### Dates in JSON-LD aren't valid — `templates/post.html`
`datePublished` renders as `04/21/2025`. Schema.org/Google expect ISO 8601 (`2025-04-21`). Google may ignore the date entirely right now, which hurts "freshness" display in results. Either output ISO from easyblog (e.g. a `{{ .ISODate }}` field) or switch the frontmatter format.

`dateModified` is also hard-wired to `.Date`. If you ever update a post, support an optional `Updated:` frontmatter field and use it here (and show "Updated on …" in the header — readers like it too).

### Flesh out `BlogPosting` structured data
Currently: headline, image, dates, author. Add:
```json
"description": "{{ .Summary }}",
"mainEntityOfPage": "https://kv.codes/post/...",
"author": { "@id": "https://kv.codes/#person" },
"publisher": { "@id": "https://kv.codes/#person" },
"keywords": "{{ join .Tags \", \" }}"
```
Linking `author` to the `#person` `@id` ties every post to the Person entity on `/about`, which is what builds a knowledge panel over time.

### Sitemap is missing your static pages
The live `sitemap.xml` has posts and tags but not `/`, `/about`, or `/hello`. `/about` is arguably your most important page for "Kenton Vizdos" searches. Add static pages (and `<lastmod>` on every entry) in easyblog's sitemap generator.

### robots.txt doesn't point to the sitemap
The live robots.txt is Cloudflare's managed content-signals file with no `Sitemap:` line. Add `Sitemap: https://kv.codes/sitemap.xml` (via a `static/robots.txt` or the Cloudflare dashboard). Also submit the sitemap in Google Search Console and Bing Webmaster Tools if you haven't — that's where you'll see what's actually indexed and which queries you rank for.

### Images have no alt text
Every `![](...)` in posts has an empty alt — 10 images across the Docker, SSD, Buttons, and Turnstile posts. That's an accessibility miss (awkward for a site that talks about accessibility) and loses image-search traffic. E.g. `![pprof CPU flame graph showing JSON decoding dominating](...)`.

### Small template cleanup
- `post.html` has the Google Fonts `preconnect` pair twice.
- The breadcrumb JSON-LD does `index .Tags 0` — a post with no tags will break the build or render bad JSON. Guard it with `{{ if .Tags }}`.
- Consider a `<meta name="twitter:card" content="summary_large_image">` — Bluesky and others fall back to it for large previews.

---

## 2. Things readers will notice

### Add an RSS/Atom feed
`/rss.xml`, `/feed.xml`, `/atom.xml` all 404. Dev-blog readers live in feed readers, and feeds are how aggregators (and things like Hacker News / Lobsters regulars) follow you. You already did the IndieWeb work (webmention, h-entry, h-card) — a feed is the missing piece. Add `<link rel="alternate" type="application/rss+xml" href="/rss.xml">` to every page's `<head>`.

### Cleaner post URLs
Filenames become URLs directly, so you get:
- `/post/Bottlenecked-by-My-SSD-—-Not-My-Code:-Searching-Roughly-3M-JSON-Records-in-130ms` (em-dash + colon, percent-encoded when shared)
- `/post/One-File,-No-Merge` (comma)

These look broken when pasted into chat, and colons in paths can trip some tools. Support a `Slug:` frontmatter field (or auto-slugify to lowercase ASCII, hyphens only) going forward. **Don't change existing URLs** without a redirect — they may already have links and webmentions pointing at them.

### Related / next posts
At the bottom of each post, link 2–3 posts sharing a tag. It keeps readers on-site and gives Google internal links between related content (your Docker and Go posts would cluster nicely).

### Reading time + table of contents on long posts
The SSD post is 200+ lines. A short TOC (from `##` headings) and "8 min read" help skimmers and can produce jump links in Google results.

---

## 3. Content

### The big one: you haven't published since November 2025
Last post: *One File, No Merge* (11/11/2025). Before that you were posting every week or two (March–July 2025). Search engines and readers both reward consistency more than volume. Even one solid post a month beats bursts.

### Turn the talk into a post
You've now given *The Integrity Illusion* twice (USDLA June 2026, MCTA October 2026), and nothing about it is on the blog. That's your most distinctive material — very few dev blogs are talking about the economics of academic integrity. Ideas:
- A write-up of the talk with the ecosystem map as a diagram.
- What came out of the live "Ecosystem Mapping" session.
- Slides, if you're comfortable sharing them (you already license presentations as CC BY-NC-SA in the footer).
- Link it from the Speaking card on `/about`.

That also creates a page people can find when they Google the talk title after seeing it at a conference.

### Finish (or kill) the WIP drafts
Five are sitting in `posts/WIP-*`:
- *Deploying a Honeypot*
- *Is This A Real Vulnerability*
- *JavaScript Dates Are a Mess*
- *Making Accessible Bar Charts With Pure CSS And No SVGs*
- *Bookmark Demo* (has placeholder "Demo Name" author and a Docker summary — looks like a test)

The bar charts one is a great fit: accessibility + CSS + "no SVGs" is a specific, searchable angle that people actually look for. Honeypot pairs well with *Phishing in the Wild*, which is your most story-driven post.

### Lean into what makes you different
Most Go/JS blogs are interchangeable. Yours has three angles that aren't:
1. **K–12 / EdTech engineering**: building for schools (enrollment, ecommerce, "sending faxes with code"). War stories from that world are rare and memorable.
2. **Security in education**: *Phishing in the Wild* targeted schools. More of this.
3. **Performance deep dives with numbers**: *91% faster Docker builds*, *3M records in 130ms*. Concrete-number titles are your best-performing format; do more of them.

### Write titles for the search, not just the reader
*Debouncing* and *go-mux* are terse. Compare to *How to fix Docker BuildX lfstack push Error*, which matches exactly what someone types into Google. You already support a `Title:` override separate from the filename — use it to write a searchable title (e.g. *"Debouncing in JavaScript: what it is and when to use it"*).

### A `/speaking` page (later)
Once there are 3+ talks, give them their own page with `Event` structured data per talk (name, date, location, organizer). For now the card on `/about` is the right size. You could also add the talks to the `Person` JSON-LD on `/about` via `"performerIn"`.

---

## 4. Off-site

- **Edvizion ↔ kv.codes:** make sure edvizion.com links back to `kv.codes/about` from a team/founders page. A link from a related domain helps both.
- **Conference pages:** ask USDLA and MCTA if the session listings can link to your about page or the talk write-up.
- **Cross-post summaries to Bluesky/LinkedIn** with a link back, and let webmentions show the replies on the post.
- **Add `kv.codes` to your GitHub profile** website field and pinned-repo READMEs (easyblog itself is a good one, since it powers the site).

---

## Suggested order

1. Homepage meta + canonical + ISO dates + sitemap static pages + robots `Sitemap:` line (one easyblog release)
2. Submit to Search Console
3. Alt text pass on existing posts
4. RSS feed
5. Publish the talk write-up
6. Finish the bar-charts WIP
7. Then aim for a monthly cadence
