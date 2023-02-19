+++
title = "Ray Casting in 2KB with Rust"
description = "Learn about raycasting and discover some elegant math by creating a tiny 4KB game with Rust."
date = "2023-02-18"
draft = true
useRelativeCover = true
cover = "cover.png"
+++

## Introduction

In this post we will uncover an elegant algorithm and create tiny first-person game with Rust.
I wrote this because I couldn't find any solid in-depth resources about ray casting while designing my own game.
This post only assumes you have a basic basic knowledge of high-school trigonometry and Rust.

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

*Add Diagram Here*

Replace "path" with "ray" and "trace" with "cast" and now you know why it's called ray casting.

{{< figure
  src="https://upload.wikimedia.org/wikipedia/commons/e/e7/Simple_raycasting_with_fisheye_correction.gif"
  position="center"
  caption="For clarity, all the individual rays in this figure are condensed into a single shape."
>}}

### Digging Deeper

On paper it seems simple to draw a line and stop when it hits a wall, in practice it can be [pretty difficult](https://en.wikipedia.org/wiki/Collision_detection).
If you had to come up with a ray casting implementation yourself, how would you approach it?

*Add Diagram Here*

The first idea most people would probably have is to repeatedly extend the ray a small amount and stop when it hits a wall.
This is problematic because when extending the ray we might skip over the wall and miss it entirely.

*Add Diagram Here*

Another idea you might have is to extend the ray to the edge of the map then check if any of the sides of the wall intersect with the ray through a simple [line-line intersection check](https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection).
Then you can calculate the distance to the nearest wall by using the smallest of the distances you found.
This is also problematic because the algorithm's [complexity](https://en.wikipedia.org/wiki/Time_complexity) increases with each wall that we add to the map.

*Add Diagram Here*

The answer, as you might have guessed from the earlier foreshadowing, is to align the map to a grid.
If we align each wall to a grid section, we know that the ray can only intersect with the wall along grid lines.
With this information, we can just repeatedly extend the ray out to the next grid line (integer) and check to see if it's about to intersect with a wall.

*Add Diagram Here*

To narrow down how we'll do this exactly, lets look at two different types of these intersections:

#### Horizontal Intersections

#### Vertical Intersections

## Implementation
Okay, time for the thing you're all here for, that big 4KB.

### WASM-4?

### Project Setup
```rust
#![no_std] // the whole point

use core::f32::consts::{FRAC_PI_2, PI}; // pi & pi / 2
```


```rust
struct Game {
    player_x: f32,
    player_y: f32,
    player_angle: f32,
    map: [u16; 16],
}
```

```rust
static mut GAME: Game = Game {
    player_x: 1.5,
    player_y: 1.5,
    player_angle: PI,
    map: [
        0b1111111111111111,
        0b1000001010000101,
        0b1011100000110101,
        0b1000111010010001,
        0b1010001011110111,
        0b1011101001100001,
        0b1000100000001101,
        0b1111111111111111,
    ],
};
```

#### Why The Weird Map?

### Horizontal Intersections


### Vertical Intersections


### Why Do My Walls Look So Funny?

### Even Smaller!

### Even Smaller?!

## Conclusion

[^1]: In this post I call specific the ray casting algorithm used in games like Wolfenstein 3D "ray casting" for the sake of brevity. This is slightly innacurrate as ray casting has a more general meaning in the field of graphics. See the [Wikipedia Article](https://en.wikipedia.org/wiki/Ray_casting).
