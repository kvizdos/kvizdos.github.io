---
Date: 04/21/2025
Summary: "A quick dive into the Web Share API: how it works, when to use it, and why it's surprisingly useful for modern web apps (especially on mobile). Includes code, fallbacks, and a few UX tips."
Author: Kenton Vizdos
Tags: JavaScript, Guides
---

## What is the Web Share API?

The Web Share API is a modern web standard that allows web applications to share content directly from the browser to other applications or services. It provides a simple and secure way for users to share text, URLs, and files without leaving the web page.

While not totally common, they are useful, in my opinion. They have a decent UX, especially on mobile devices. If you haven't used one before, give the "Share this Post" button a try!

### How does the Web Share API work?

The Web Share API works by providing a set of JavaScript APIs that allow web applications to share content directly from the browser to other applications or services. It uses the `navigator.share()` method to initiate the sharing process. This method takes an object with properties such as `title`, `text`, and `url`, and opens a native sharing dialog on the device:

```js
navigator.share({
  title: 'Web Share API',
  text: 'This post is about the Web Share API! Give it a look.',
  url: 'https://kv.codes/post/Web-Share-API'
});
```

That's really it! It's a very simple API, and.. it exposes some helpful tools.

### Was it Shared?

The great part about this API is that you can detect *if* it was shared successfully. The `navigator.share()` method returns a promise that resolves if the sharing was successful, and rejects if it failed. You can use this to provide feedback to the user:

```js
navigator.share({
  title: 'Web Share API',
  text: 'This post is about the Web Share API! Give it a look.',
  url: 'https://kv.codes/post/Web-Share-API'
}).then(() => {
  console.log('Post shared successfully!');
}).catch((error) => {
  console.error('Cancelled sharing post:', error);
  // This is essentially a cancel.
});
```

While you can detect a boolean of whether or not it was shared successfully, you cannot see *where* it was shared.

This is useful if you're tracking engagement: you can log an event when the share promise resolves or rejects. It's not where it was shared, but it's still useful (I use PostHog to track these basic events).

## Parameters

The `navigator.share()` method takes an object with the properties:

- `title`: The title of the content to be shared (this CAN be ignored by the target platform!).
- `text`: The text to be shared.
- `url`: The URL of the content to be shared.
- `files`: An array of files to be shared (I haven't used this, so I won't be touching on it much here).

My blog uses the following data:

```js
{
    title: "{{.Title}}",
    text: "I just learned some cool things from kv.codes:",
    url: "https://kv.codes/post/{{.OGName}}",
}
```

## Support

The Web Share API is supported in modern browsers, including Chrome, Firefox, Safari, and Edge. However, it is not supported in Internet Explorer or older versions of Android browsers. You can check for support using the `navigator.share` property:

```js
if (navigator.share) {
  // Web Share API is supported
} else {
  // Web Share API is not supported
}
```

On this blog, I detect whether or not the Web Share API is available, and if it is not, I fallback to a copy-to-clipboard solution. It's not perfect, but it's better than nothing!

```js
if (navigator.share) {
  navigator.share({ title, text, url });
} else {
  navigator.clipboard.writeText(url);
  alert("Link copied!");
}
```
