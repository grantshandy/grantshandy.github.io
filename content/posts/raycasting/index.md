+++
title = "Work In Progress - Write a 2KB FPS with Rust"
description = "Learn about raycasting and discover some elegant math by creating a tiny 4KB game with Rust."
date = "2023-02-18"
draft = false
math = true
useRelativeCover = true
cover = "cover.png"
+++

## Introduction
In this post we will uncover an elegant algorithm and create tiny first-person game with Rust.
I wrote this because I couldn't find any solid in-depth resources about ray casting while designing my own game.
Here's a quick preview of what we'll be making:

{{< imgproc "preview.gif" Resize "480x480" center />}}

My first experience with games like this (though I didn't know at the time), was in middle school with games like [zDoom](https://www.ticalc.org/archives/files/fileinfo/360/36062.html) for the TI-84 plus.
ZDoom (while probably not as fun as [snake](https://www.ticalc.org/archives/files/fileinfo/336/33606.html)), provided the feeling of playing a "cool" game because of it's unique "3D" graphics and brand association.
zDoom, while only an imitation of the original Doom, is much closer to it's technical predecesor, Wolfenstein 3D.

### Wolfenstein 3D
Famously, [Wolfenstein 3D](https://en.wikipedia.org/wiki/Wolfenstein_3D), released in 1992, was one of the first 3D first-person games to run on consumer PCs.
Back then, computers didn't have 3D acceleration, let alone dedicated graphics cards, so how was this done?

{{< figure src="https://upload.wikimedia.org/wikipedia/en/6/69/Wolf3d_pc.png" position="center" caption="A screenshot from wolfenstein 3D" >}}

Well, I should have said [*pseudo*-3D](https://en.wikipedia.org/wiki/2.5D) because no part of the game actually ran in three-dimensions.
The core of the game was an algorithm called ray casting[^1], a process of projecting a 2D map into a 3D perspective.

All the game entities were located only at simple x and y positions on the map and could not move vertically.
Upon release, I'm sure that this didn't show, but with our [current standards](https://www.unrealengine.com/en-US/unreal-engine-5) it definitely does.
The player could not look up or down, let alone crouch or jump.

{{< figure src="wolfenstein-map.png" position="center" caption="A top-down view of the first level of Wolfenstein 3D" >}}

To add to that, all levels were composed of single floors of buildings with no windows.
Also, all walls were perfectly straight with corners placed at even intervals (something that will definitely not come up later).
These design features were all put here because of some of the essential restrictions of it's simple ray casting algorithm.

## The Algorithm
### The Basics
At the most fundamental level, ray casting depends on the simple fact that objects that are further away from us appear smaller, while objects that are closer appear larger.
Ray casting uses this fact to draw draw walls at shorter heights the further away they from the player and taller heights the closer they are.

Just this simple idea alone creates a convincing illusion of depth and allows us to move our player around just as if it were being rendered in actual 3D.

Ray casting *works* by tracing a path from the player to the closest wall for each vertical column in the player's view.
It then records the distances of each paths before converting it into the height of a wall and drawing it on screen.

{{< figure src="figure-overview.svg" position="center" >}}

Replace "path" with "ray" and "trace" with "cast" and now you know why it's called ray casting.

{{< figure
  src="https://upload.wikimedia.org/wikipedia/commons/e/e7/Simple_raycasting_with_fisheye_correction.gif"
  position="center"
  caption="A visualization of the algorithm."
>}}

### Digging Deeper
On paper it seems simple to draw a line and stop when it hits a wall, in practice it can be [pretty difficult](https://en.wikipedia.org/wiki/Collision_detection).
If you had to come up with a ray casting implementation yourself, how would you approach it?

{{< figure src="figure-question.svg" position="center" caption="The Intersection Problem" >}}

The first idea most people would probably have is to repeatedly extend the ray[^2] a small amount and stop when it hits a wall.
This is problematic because when extending the ray we might skip over the wall and miss it entirely.

{{< figure src="figure-naive.svg" position="center" caption="The Naive Solution" >}}

Another idea you might have is to extend the ray to the edge of the map then check if any of the sides of the wall intersect with the ray through a simple [line-line intersection check](https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection).
Then you can calculate the distance to the nearest wall by using the smallest of the distances you found.
This is also problematic because the algorithm's [complexity](https://en.wikipedia.org/wiki/Time_complexity) increases with each wall that we add to the map.

{{< figure src="figure-line-intersections.svg" position="center" caption="Line-Intersection Checking" >}}

The best answer, as you might have guessed from the earlier foreshadowing, is to align the map to a grid.
If we align each wall to a grid section, we know that the ray can only intersect with the wall along grid lines.
With this information, we can just repeatedly extend the ray out to the next grid line (integer) and check to see if it's about to intersect with a wall.

{{< figure src="figure-solution.svg" position="center" caption="Wall-Line Intersection Checking" >}}

The way we'll implement this takes strategies from both of the approaches previously mentioned.
First, we'll extend the ray along horizontal grid intersections, then we'll extend along vertical grid intersections.
After this we can simply choose the smaller of the two to find how far the wall is away from the player!

### Horizontal Intersections
{{< geogebra file="ggb/horizontal.ggb" name="horizontal" >}}

The nice thing about an evenly spaced grid is that the distance between grid intersections is constant.
In the case of horizontal grid intersections, the height between intersections is always 1, while the width can be derived from the angle of the ray.

You can see this by looking at the diagram, the width between Z and Y is the same as the width between X and Y, and the vertical distance between all points is one.
Using some simple trigonometry we can find the width between horizontal grid intersections.
I'm going to save you the work and just give you the definition: [^3]

$$ \Delta H = \begin{cases} 1 &\text{if } \pi > \theta \ge 0  \text{ (facing up)} \\\ -1 &\text{if } \tau > \theta \ge \pi \text{ (facing down)} \end{cases} $$
$$ \Delta W = \frac{\Delta H}{\tan(\theta)} $$
### Vertical Intersections
{{< geogebra file="ggb/vertical.ggb" name="vertical" >}}

Vertical grid intersections are the same as horizontal grid intersections, just rotated 90°.
In vertical grid intersections the width between our "ray extensions" is the constant, while the height is created from the angle of the ray.
Like last time, I'm going to skip ahead and define our variables for you. [^3]

$$ \Delta W = \begin{cases} 1 &\text{if } \pi/2 > \theta > -\pi/2 \text{ (facing right)} \\\ -1 &\text{if } 3\pi/4 > \theta > \pi/2 \text{ (facing left)} \end{cases} $$
$$ \Delta H = \Delta W * \tan(\theta) $$

### Overview
With all the information we've learned, we can write up the algorithm.

For each vertical line on screen:
1. Find the relative angle from the player's angle and field of view.
2. Cast two rays from the player at our angle. One checks for horizontal intersections with walls and the other checks for vertical intersections.
3. Choose the smaller of the two intersections and draw a vertical line on the screen proportional to the distance to the wall.

## Implementation
Now that we understand how the underlying algorithm works we can write a program that implements it using Rust and WASM-4.

### WASM-4?
[WASM-4](https://wasm4.org) is a tiny game engine which runs WebAssembly (`.wasm`) files.
Most compiled languages (C, C++, Rust, Zig, etc.) can compile to WebAssembly, so games for WASM-4 can be written in any of those languages.
WASM-4 is extremely minimal, it is named "WASM-4" because it executes `.wasm` files, and only lets you draw four colors on screen at once.

{{< mermaid >}}
graph LR
    source[lib.rs] --> compiler[rustc] --> wasm
    subgraph wasm4[WASM-4]
        wasm[game.wasm]
    end
    wasm4--> player[Player]
{{< /mermaid >}}

In our case, WASM-4 is very useful because it lets us create tiny, self-contained games and provides helpful functions like `vline`.
All you need to run WASM-4 games is to [download and install the minimal runtime](https://wasm4.org/docs/getting-started/setup).

### Project Setup
Because WASM-4 runs WebAssembly files, we have to configure our cargo project accordingly (with a few minor tweaks).

```sh
$ cargo new raycaster --lib && cd raycaster
```

Add to `Cargo.toml`:
```toml
[lib]
crate-type = ["cdylib"]

[profile.release]
opt-level = "z"
lto = true
```
This will tell cargo that we want to produce a C-like dynamic library (`.wasm`), and optimize the binary for size.

In our cargo project configuration file `.cargo/config.toml` add:
```toml
[build]
target = "wasm32-unknown-unknown"

[target.wasm32-unknown-unknown]
rustflags = [
    # Import memory from WASM-4
    "-C", "link-arg=--import-memory",
    "-C", "link-arg=--initial-memory=65536",
    "-C", "link-arg=--max-memory=65536",
    "-C", "link-arg=-zstack-size=14752",
]
```
This will tell cargo to compile our project to WebAssembly by default, and pass some flags to `rustc` telling our program to reserve some memory for the game.

### Horizontal Intersections


### Vertical Intersections


### Why Do My Walls Look So Funny?

### Even Smaller!

### Even Smaller?!

## Conclusion

[^1]: In this post I call specific the ray casting algorithm used in games like Wolfenstein 3D "ray casting" for the sake of brevity. This is slightly innacurrate as ray casting has a more general meaning in the field of graphics. See the [Wikipedia Article](https://en.wikipedia.org/wiki/Ray_casting).
[^2]: To say "extending the ray" is a bit of a misnomer. "vector" is more accurate in this situation but "ray" sounds better.
[^3]: This definition is slightly different than what is in the implementation because our player angle won't always be between 0 and 𝜏. The coordinate system will also be vertically flipped.