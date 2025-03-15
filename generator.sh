#!/bin/bash
for i in {1..100}; do
  cp "./posts/demo-post.md" "./posts/demo-post-$i.md"
done
