---
Date: 03/26/2025
Summary: "This post humorously exposes the hidden chaos behind designing what appears to be a simple button. From basic styling to a labyrinth of states, variations, and accessibility tweaks, the rant reveals how a single UI element can escalate into a full-blown designer's nightmare."
Author: Kenton Vizdos
Tags: Design, Rant
---

## So you want to design a button.

"It's easy, right? It's a box, with some text":

![](/assets/blog/buttons/basic-button.svg)
A Button; just that.

Yeah, stakeholder.. they are easy.

Until you need to do absolutely anything with the button. Like clicking it.

![](/assets/blog/buttons/basic-button-click.svg)
An Ugly Button in an "Active" State

Okay.. so.. fix that up. And oh, while your at it, you decide to add a hover state.

![](/assets/blog/buttons/button-hover.svg)
A Button in a "Hover" state

We are now up to 3 variations: it's perfect!

### Can't forget the :focus!

We here at (insert company) are heavily a11y (accessibility) compliant, so our buttons need a custom focus state:

![](/assets/blog/buttons/button-focus.svg)
Button with a Focus state

Okay! We're now cooking with gas.. what else could we need?

*Developer Tip: Use outline instead of border, it won't cause a layout shift :)*

**Variation Counter**: 4

### Wait, I also need to control the size

For times when you need a big or small button, of course.

Now, you have a `small`, `regular`, and `large` button.

Of course, each one of these needs to modify the border radius, font size, etc. And of course, the `:focus` state of each variant needs some work as to not look odd.

**Variation Counter**: 12 (uh oh)

### Icons! I want an Icon on this button!

said your project manager.

And you cried. The button apocalypse is beginning.

The PM insists on having the option of `icon text` `text icon` and `icon only` buttons.

we now have.. so many variations; yet, we're still so far away from the end..

**Variation Counter**: 36 (this is beginning to snowball..)

### Make that button red! Its dangerous!

Oh boy.. we can't have our "Delete Account" button be the same color. Blasphemy!

**Variation Counter**: 72 (i'm peeling my eyes out rn..)

### They all look too similar now.

We now need to add in a hierarchical and palette versions..

**Variation Counter**: two hundred an- okay I'm out. **Fuck this.**

## Buttons are a pain in the ASS.

This barely scratches the surface: we haven't even tackled tints, disabled state, loading state, and all the other critical pieces that multiply every variation.

[Designers say there are roughly 720 variations to a button.](https://cieden.com/book/atoms/button/how-to-organize-buttons-in-design-system)

What starts as a simple element quickly becomes a labyrinth of tweaks and compromises. Let this be a lesson to anyone new: buttons will be the bane of your hellish existence.

Even though coding them might seem easier considering CSS cascades, the state management alone can drive you up the wall. So the next time someone casually asks you to 'just design a simple button' or 'just change the color,' smile politely and quietly scream inside, knowing the button apocalypse awaits.
