---
Date: 03/16/2025
Summary: I built a static blog generator using Go's concurrency model, leveraging pipelines for parallel processing. The result? 1,000 posts built in 25ms!
Author: Kenton Vizdos
Tags: Go, Concurrency, Thinking Out Loud
---

## The Inspiration

I've been working with Go for over 2 years now, and through that time, I've slowly been moving more into a concurrent mindset. That being said, I still haven't had enough time to fully understand *what* the power can be.

Also, I've always disliked my blog design.. so I thought: "This is the perfect time to make (another) blogging system!" Why use existing technology when you can spend a weekend and learn 10x more? :)

My constraints for this blog system were:

- Posts need to be written in Markdown, converted to HTML.
- Posts need an OG Image to be created automatically
- It needs to be fast (less than 1 second for 1,000 posts)

Thinking over these requirements, a Pipeline concept seemed like an ideal candidate, especially with my overarching goal of learning more concurrency patterns. This pattern makes it easy to add steps as needed while ensuring the system doesn't get overwhelmed by tracking 'maximum in progress' tasks.

## What is a Pipeline?

A pipeline in concurrent programming is a design pattern where a task is divided into a series of stages, with each stage handling a specific part of the process. Data flows from one stage to the next, often concurrently, allowing for efficient and scalable processing.

Pipelines simplify complex, multi-step processes by breaking them into manageable, concurrent stages. This design pattern not only enhances performance through parallelism but also makes the code more modular and maintainable, a perfect fit for projects where speed and scalability are paramount. (for my blog system with 2 whole posts, speed and scalability are CRITICAL! can't be waiting more than 1s for my.. 2 posts to go live)

### Conceptual Overview

Imagine a production line in a factory:

- **Stations:** Each station (or stage) performs a specific operation on an item.
- **Data Flow:** Items move seamlessly from one station to the next, with each station contributing to the final product.
- **Parallel Processing:** Multiple items can be processed at different stations simultaneously, improving overall throughput.

In Go, each stage of the pipeline is typically implemented as a separate function running in its own `goroutine`. Channels serve as the communication link between these stages, ensuring that data is passed safely and efficiently.

### Benefits of Using a Pipeline

- **Modularity:** Each stage is self-contained, making it easier to maintain and modify without affecting the entire system.
- **Scalability:** Pipelines can handle increased workloads by processing multiple items concurrently, making them suitable for high-throughput systems.
- **Efficiency:** By overlapping operations across different stages, pipelines minimize idle time and maximize resource utilization.
- **Flexibility:** Additional stages can be inserted or removed as needed, enabling easy adaptation to changing requirements or additional features.

## Blog Architecture

The great part about a pipeline is that it can nearly fit identically to what the constraints were:

- Load a "posts" directory and find all of the markdown files
- Pass those into 2 channels: one for parsing, and one for OG image creation.
- Once the OG image is created, write it to a file.
- Once the parsing is done, pass the HTML data to an HTML-template-filling function
- Once the template is filled, write to disk.
- Finally, collect all posts and create an index page

Since these all get converted to static HTML files, I want the end result to be able to get pushed to GitHub Pages.

## Implementation Overview

Here's a snippet of how I orchestrated the build process. Notice the clean separation between scanning, processing, and writing: this structure allows for scalable, maintainable code. I'm sure it could be nicer; and it definitely started out looking better in the beginning, though as usual, complexities get added along the way:

```go
func (b *Builder) Build() {
	// waiting groups to ensure that HTML templates & directory scaffolding are READY prior to use
	b.setupWaitGroup.Add(2)
	b.staticFilesCreated.Add(2)

	// Start a goroutine to parse out the HTML templates into template/html
	go b.setupHTML(b.Config.InputDirectory)
	// Scaffold the output directory
	go b.setupOutDirectory()

	// Finally, we can start scanning for markdown files within our
	// input directory. This function will return two channels:
	// one for "Post" data, and one just for metadata (for use in index pages)
	postsChan, metadataChan := b.scanForMarkdownFiles(b.Config.InputDirectory)
	// Start a Go routine to watch on the metadata channel for new posts;
	// this will wait until all posts are done, and then write it out to the
	// index file.
	go b.buildIndexHTML(metadataChan)
	// At the same time, start converting the markdown into HTML
	// and then stuff it into the HTML templates
	doneCh := b.buildPost(postsChan) // spins up another Go Routine for OG Image Creation, and fills template HTML w/ post.
	// As posts get finalized, write them to disk as soon as possible.
	b.writePostOut(doneCh)

	// Wait for the index pages to be completed.
	b.staticFilesCreated.Wait()
}
```

An important part of the magic comes from the WaitGroups. Since "setupHTML" and "setupOutputDirectory" are processed through a `goroutine`, the `buildIndexHTML` and `buildPostHTML` SHOULD NOT begin until the `index.html` and `post.html` template files are ready (e.g., been parsed from `template/html`).

This was easily overcome by using WaitGroups to enforce the correct order. For a simple example, take a look at this code:

```go
var wg sync.WaitGroup
wg.Add(2)

// Then, from some Go routine:
go func() {
	time.Sleep(10 * time.Second)
	fmt.Println("Go Routine 1")
	wg.Done()
}()

fmt.Println("Hello")

go func() {
	time.Sleep(5 * time.Second)
	fmt.Println("Go Routine 2")
	// And another go routine:
	wg.Done()
}()

wg.Wait()

fmt.Println("Done!")
```

Within this example code, the output would look like this:

```bash
> Hello
> Go Routine 2
> Go Routine 1
> Done!
```

The beauty is in the FACT that "Done!" will **NEVER** be printed until both tasks are complete: something that is wonderful to guarantee in a concurrent system. These WaitGroups *can* also be nested, to where one `goroutine` can spin up another `goroutine`, wait till it's done, and then `.Done()` the original waitgroup.

## Challenges and Learnings

Concurrency in Go is both powerful and complex. Throughout this project, I encountered challenges ranging from subtle race conditions to orchestrating goroutine synchronization with wait groups. These hurdles turned into valuable lessons on building robust concurrent systems.

The most significant challenge was dealing with deadlocks. I often found goroutines waiting indefinitely on channel communications that never occurred. Debugging these issues required a deeper understanding of channel mechanics and careful design of the communication flow. Each deadlock taught me to be more deliberate in structuring pipelines and managing synchronization, ultimately leading to a more resilient system.

Luckily for me, Go has deadlock detection built in (magically), which helped me detect these issues before they got too unruly. Also, one tip I learned, if you are working on Unix (e.g. Mac): sending a `SIGQUIT` signal to your Go app when it's hanging will reveal extra details in the trace about what is happening.

## The Outcome

By limiting concurrency to 5 using pooling, I was able to test out performance under realistic circumstances (e.g. CI runners). Without OG image creation, I can generate 1,000 blog posts in just 25ms. With OG image creation, that time increases to 630ms (63 microseconds per post); still well under one second. These numbers reflect a first-run scenario where each post and OG image are generated from scratch.

That's around 65% of my 1s goal with OG creation, and about 2% of my goal time without, so I am very happy in the results. However, I'm confident there is still room for growth.

I also streamlined deployment using a GitHub Action to build the blog repo and push it to GitHub Pages. One thing I love about Go is its package management: installing EasyBlog (the hyper-creative name I came up with) in a CI pipeline is as simple as:

```bash
$ go install github.com/kvizdos/easyblog
```

Then, running easyblog with `easyblog --config config.yaml` handles the blog build automatically.

The blog you are currently reading is open source at https://github.com/kvizdos/kvizdos.github.io, and EasyBlog is available at https://github.com/kvizdos/easyblog (there is a lot of customization I didn't go over here)
