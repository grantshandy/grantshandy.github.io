+++
title = "Work In Progress - Write a 2KB FPS with Rust"
description = "Learn about raycasting and discover some elegant math by creating a tiny 4KB game with Rust."
date = "2023-02-18"
draft = true
math = true
useRelativeCover = true
cover = "cover.png"
+++

## Introduction
In this post we will uncover an elegant algorithm and create tiny first-person game with Rust.
If you're not interested in how it's done and just want to see the source code you're welcome to skip the post.

The goal here is to recognize the problem, break it down, and discover a graceful solution from scratch.
My job is to walk you through solving this problem so you can discover it yourself.

I wrote this because I couldn't find any in-depth resources about ray casting while designing my own game.
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

Okay, so from what we know so far the raycasting algorithm is as follows:

For each vertical line on screen:
 - Cast a ray from the player and stop at the nearest wall.
 - Calculate the distance from the player to that nearest wall.
 - Convert that distance into the height of a wall and draw it on screen.

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

{{< figure src="figure-solution.svg" position="center" caption="Grid-Line Intersection Checking" >}}

The way we'll implement this takes strategies from both of the approaches previously mentioned.
First, we'll extend the ray along horizontal grid intersections, then we'll extend along vertical grid intersections.
After this we can simply choose the smaller of the two to find how far the wall is away from the player!

### Horizontal Intersections
{{< geogebra
    file="ggb/horizontal.ggb"
    name="horizontal"
    caption="Drag the player around to see how the ray intersects with the grid lines."
    coords="-2.78, 13.18, -4.48, 7.48" >}}

The nice thing about an evenly spaced grid is that the distance between grid intersections is constant.
In the case of horizontal grid intersections, the height between intersections is always 1, while the width can be derived from the angle of the ray.

You can see this by looking at the diagram, the width between Z and Y is the same as the width between X and Y, and the vertical distance between all points is one.
Using some simple trigonometry we can find the width between horizontal grid intersections.
I'm going to save you the work and just give you the definition: [^3]

$$ \Delta H = \begin{cases} 1 &\text{if } \pi > \theta \ge 0  \text{ (facing up)} \\\ -1 &\text{if } \tau > \theta \ge \pi \text{ (facing down)} \end{cases} $$
$$ \Delta W = \frac{\Delta H}{\tan(\theta)} $$
### Vertical Intersections
{{< geogebra
    file="ggb/vertical.ggb"
    name="vertical"
    caption="Drag the player around to see how the ray intersects with the grid lines."
    coords="-3.097, 8.238, 2.274, 10.769"
>}}

Vertical grid intersections are the same as horizontal grid intersections, just rotated 90°.
In vertical grid intersections the width between our "ray extensions" is the constant, while the height is created from the angle of the ray.
Like last time, I'm going to skip ahead and define our variables for you. [^3]

$$ \Delta W = \begin{cases} 1 &\text{if } \pi/2 > \theta > -\pi/2 \text{ (facing right)} \\\ -1 &\text{if } 3\pi/4 > \theta > \pi/2 \text{ (facing left)} \end{cases} $$
$$ \Delta H = \Delta W * \tan(\theta) $$

### Summary
We can compile all these steps into a step-by-step list for the computer to follow (an algorithm):

For each vertical line on screen:
1. Find the angle for the ray from the player's angle and field of view.
2. Cast two rays from the player at that angle. One stops at horizontal intersections with walls and the other stops at vertical intersections with walls.
3. Choose the smaller of the two distances and draw a vertical line on the screen proportional to that distance.

## Implementation
Now that we understand how the underlying algorithm works we can write a program that implements it using Rust and WASM-4.

 > Wait why do we need WASM-4?

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

We need WASM-4 because it lets us create tiny, self-contained games and provides a simple platform for us to build our game off of.
WASM-4 will handle windowing, graphics rendering, and gamepad input, we'll have to do everything else.
All you need to run WASM-4 games is to [download and install the minimal runtime](https://wasm4.org/docs/getting-started/setup).

### Project Setup
Because WASM-4 runs WebAssembly files, so we have to configure our project to create one.

```sh
$ cargo new raycaster --lib && cd raycaster
```

Add this to to `Cargo.toml`:
```toml
[lib]
crate-type = ["cdylib"]

[profile.release]
opt-level = "z"
lto = true

[dependencies]
libm = "0.2"
```
This will tell cargo that we want to produce a C-like dynamic library (`.wasm`), and optimize the binary for size.
{{< newtabref href="https://crates.io/crates/libm" >}}`libm`{{< /newtabref >}} is a library which will provide us some `no_std` implementations of functions we need like `sin`, `tan`, and `floor`. (more on that later)

In our crate configuration file `.cargo/config.toml` lets add:
```toml
[build]
target = "wasm32-unknown-unknown"

[target.wasm32-unknown-unknown]
rustflags = [
    "-C", "link-arg=--import-memory",
    "-C", "link-arg=--initial-memory=65536",
    "-C", "link-arg=--max-memory=65536",
    "-C", "link-arg=-zstack-size=14752",
]
```
This will tell cargo to use WebAssembly by default and pass some flags to rustc which tell our program to reserve some memory for the game.

Now, lets add some simple boilerplate to `src/lib.rs`:
```rust
#![no_std]

use core::{arch::wasm32, panic::PanicInfo};

const GAMEPAD1: *const u8 = 0x16 as *const u8;

const BUTTON_LEFT: u8 = 16;  // 00010000
const BUTTON_RIGHT: u8 = 32; // 00100000
const BUTTON_UP: u8 = 64;    // 01000000
const BUTTON_DOWN: u8 = 128; // 10000000

extern "C" {
    fn vline(x: i32, y: i32, len: u32);
}

#[panic_handler]
fn phandler(_: &PanicInfo<'_>) -> ! {
    wasm32::unreachable();
}

#[no_mangle]
unsafe fn update() {
    if *GAMEPAD1 & BUTTON_UP != 0 {
        vline(80, 20, 120);
    }
}
```
Here's a little explanation for those not in the loop:
 - `#![no_std]` prohibits the program from using the Rust standard library. This is essential in almost all WASM-4 games because the standard library is large and might put our game over the 64KB size limit.
 - {{< newtabref href="https://wasm4.org/docs/reference/memory#gamepads" >}}`GAMEPAD1`{{</ newtabref >}} is a pointer to the current state of the first gamepad (the arrow keys in our case). The WASM-4 runtime running our program will keep it to date with our inputs on each frame.
 - The constants `BUTTON_LEFT` through `BUTTON_DOWN` describe the bits in the gamepad which indicate that the button is down on the current frame.
 - `extern "C" ... fn vline` links our game to the external function {{< newtabref href="https://wasm4.org/docs/reference/functions/#vlinex-y-len" >}}`vline`{{</ newtabref >}} which WASM-4 provides for us.
 - `#[panic_handler] fn phandler` is a little bit of boilerplate that Rust requires we provide if we choose to use `#![no_std]`. This function will run when the program panics, and because WASM-4 is such a restrictive environment, the only thing we can really do is call `wasm32::unreachable()`.
 - {{< newtabref href="https://wasm4.org/docs/reference/functions/#update-" >}}`fn update`{{</ newtabref >}} is a function that WASM-4 will call on each frame so it's the main place we will be writing our game. Adding `#[no_mangle]` to our function stops rustc from "mangling" the symbol for `update` so WASM-4 can call it.

To compile our game we can build it just like any other crate:
```sh
 $ cargo build --release
```

And to run it we can use `w4 run-native`:
```sh
 $ w4 run-native target/wasm32-unknown-unknown/release/raycaster.wasm
```

This will launch an empty window, and if we press the up arrow on the keyboard a vertical line will appear in all its gameboy-ish glory.

{{< figure src="screenshot-one.png" position="center" caption="It's alive!" >}}

One thing I like to do in this sort of situation is to put these commands in a `Makefile` so we don't have to re-type the commands or over use the up arrow.
After that all we have to do to build and run the program is type `make run`.
```makefile
all:
    cargo build --release

run: all
    w4 run-native target/wasm32-unknown-unknown/release/raycaster.wasm
```

Great, now that we've got the workflow down we can get to writing the game.

### Storing The Map
The simplest way to store the map is a grid of wall or no wall.
One way we could store the map as `[[bool; WIDTH]; HEIGHT]` and access it through `map[][]`.
Storing the map this way wouldn't be very elegant because we'd have to type out each cell individually as `true` or `false`.
Because the boolean value (wall or no wall) can be represented by a single bit we can use the bits inside of a number to represent the map: `[u16; HEIGHT]`.
In this case, `[u16; HEIGHT]` can represent a map with a width of 16 cells and an arbitrary height of our choosing.
Using Rust's integer literal syntax we can represent our map pretty simply by writing a `1` where there is a wall and a `0` where there is no wall:

```rust
const MAP: [u16; 8] = [
    0b1111111111111111,
    0b1000001010000101,
    0b1011100000110101,
    0b1000111010010001,
    0b1010001011110111,
    0b1011101001100001,
    0b1000100000001101,
    0b1111111111111111,
];
```

The more difficult thing about this way of storing the map is indexing into it.
In order to do this, we have to write a function which first indexes into the row, then into the specific column by masking and then shifting the row.

```rust
/// Check if the map contains a wall at a point.
fn coord_contains_wall(x: f32, y: f32) -> bool {
    match MAP.get(y as usize) {
        Some(line) => (line & (0b1 << x as usize)) != 0,
        None => true,
    }
}
```
Because our map is surrounded by walls it's safe to tell the caller of this function that there is a wall if it calls for a coordinate that is out of bounds.

### Maintaining Game State
The map stays constant throughout the runtime of the program, but the player's position and angle changes. Because WASM-4 calls `update` on each frame, the only way to store our game state across frames is via something like `static mut`.
Because `static mut` is `unsafe`, we should consolidate our behavior and state in a single struct.

Only three variables are required to store the state of our player's view: the X and Y position and the player's viewing angle.
```rust
struct State {
    player_x: f32,
    player_y: f32,
    player_angle: f32,
}    
```

Now, lets declare that `State` in memory:

```rust
static mut STATE: State = State {
    player_x: 1.5,
    player_y: 1.5,
    player_angle: 0.0,
};
```
 > *`player_x` and `player_y` are both initially set at 1.5 so the player starts in the center of a cell and not inside a wall.*

This consolidation of `unsafe` behavior into `fn update` and game logic into `State` will separate the incentives of our functions and give some structure to our program.
It gives us a pretty clear line: I/O in `fn update`, which calls, game logic in `State`.

{{< mermaid >}}
flowchart
    subgraph unsafe
        w[WASM-4] --> f[fn update]
    end

    f --> u[struct State]
{{</ mermaid >}}

### Moving the Character
One of the easier parts of our game is moving the character.
Because accessing our `State` from outside is `unsafe`, lets create a method inside of `State` to move the character and then pass in the inputs on each frame.

```rust
impl Game {
    /// move the character
    pub fn update(&mut self, up: bool, down: bool, left: bool, right: bool) {
        // store our current position in case we might need it later
        let previous_position = (self.player_x, self.player_y);

        if up {
            self.player_x += cosf(self.player_angle) * STEP_SIZE;
            self.player_y += -sinf(self.player_angle) * STEP_SIZE;
        }

        if down {
            self.player_x -= cosf(self.player_angle) * STEP_SIZE;
            self.player_y -= -sinf(self.player_angle) * STEP_SIZE;
        }

        if right {
            self.player_angle -= STEP_SIZE;
        }

        if left {
            self.player_angle += STEP_SIZE;
        }

        // if moving us on this frame put us into a wall just revert it
        if coord_contains_wall(self.player_x, self.player_y) {
            (self.player_x, self.player_y) = previous_position;
        }
    } 
}
```

If you've ever moved a player in a game before this should all look familiar.
If the player is asking us to move the player forwards or backwards we modify the player's x and y positions based on the `cosf` and `sinf` values of the player's angle multiplied by a constant `STEP_SIZE`.
The cool thing about `STEP_SIZE` is that the amount we rotate the player's angle on each frame happens to be similar to the amount we have to multiply the `cosf` and `sinf` values by to move the character.

That's convenient because it means we only have to declare one constant to control the player's speed!
Just for you, I'll give you a magic number you can change later:
```rust
const STEP_SIZE: f32 = 0.045;
```

The last thing that we need to make this function work is to import `cosf` and `sinf` from `libm`.

```rust
use libm::{cosf, sinf};
```

 > *Why `sinf/cosf` and not `sin/cos`? This naming convention comes from C where `sin/cos` handles doubles and `sinf/cosf` handles floats.*
 > *In Rust's `libm` this means `fn cos(x: f64) -> f64` and `fn cosf(x: f32) -> f32`.*
 > *Right now we're using `f32` and not `f64` because it saves space and we don't need the precision.*

The last thing we need to do... is call our new `State::update` of course!

```rust
#[no_mangle]
unsafe fn update() {
    STATE.update(
        *GAMEPAD1 & BUTTON_UP != 0,
        *GAMEPAD1 & BUTTON_DOWN != 0,
        *GAMEPAD1 & BUTTON_LEFT != 0,
        *GAMEPAD1 & BUTTON_RIGHT != 0,
    );
}
```

### Creating The View
So far we haven't written anything we can interact with.
Well we can *interact* with it, but we can't see what we're doing.
That's what the raycasting algorithm is for right?
Lets try to implement that.

If you remember from the [summary](#summary), we have to draw vertical lines for every column on the window.

We can split this up into two separate jobs: getting the heights of the lines and actually drawing them on the screen.
Why not do this all at once?
Well, `vline` is `unsafe` so lets use it in `fn update`
 Getting the player's view is game logic and should be kept in `State` where it can avoid `unsafe` usage.

Lets do this by defining `State::get_view` which returns a list of all the wall heights.
Then, on each frame, we can call `State::get_view` from `fn update` and draw all of those vertical lines we just calculated.

`State::get_view` will work by going through each vertical line on screen (all 160), calculating the angle offset from the player's point of view, then finding the distance to the closest horizontal and vertical intersections with walls in the ray's path.
Then it compares the two distances and returns the smaller of the two (after converting it into the height of the wall).

I know that sounds complicated, but lets go ahead and write out what that will look like:

First, lets import the core library's handy constant for π.
```rust
use core::f32::consts::PI;
```

Then, lets create some constants which define our player's perspective.
```rust
const FOV: f32 = PI / 2.7;
const HALF_FOV: f32 = FOV * 0.5;
const ANGLE_STEP: f32 = FOV / 160.0;
```

Then, lets add `get_view`, `horizontal_intersection`, and `vertical_intersection` to our `State` impl block.
```rust
impl State {
    pub fn get_view(&self) -> [f32; 160] {
        let starting_angle = self.player_angle - HALF_FOV;
        let mut rays = [0.0; 160];

        for (num, ray) in rays.iter_mut().enumerate() {
            let angle = starting_angle + num as f32 * ANGLE_STEP;

            let h_dist = self.horizontal_intersection(angle);
            let v_dist = self.vertical_intersection(angle);

            *ray = f23::min(h_dist, v_dist);
        }

        rays
    }

    fn horizontal_intersection(&self, angle: f32) -> f32 {
        0.0 // we'll handle this later   
    }

    fn vertical_intersection(&self, angle: f32) -> f32 {
        0.0 // this too
    }
}
```
```rust
#[no_mangle]
unsafe fn update() {
    STATE.update(
        *GAMEPAD1 & BUTTON_UP != 0,
        *GAMEPAD1 & BUTTON_DOWN != 0,
        *GAMEPAD1 & BUTTON_LEFT != 0,
        *GAMEPAD1 & BUTTON_RIGHT != 0,
    );

    for (x, ray_height) in STATE.get_view().iter().enumerate() {
        // draw line based on ray height and x position
    }
}
```

### Horizontal Intersections

### Vertical Intersections

### Drawing Walls

### Getting A New Perspective

### Adding Some Depth

## Make It Smaller!

## Even Smaller?!

## Conclusion

[^1]: In this post I call specific the ray casting algorithm used in games like Wolfenstein 3D "ray casting" for the sake of brevity. This is slightly innacurrate as ray casting has a more general meaning in the field of graphics. See the [Wikipedia Article](https://en.wikipedia.org/wiki/Ray_casting).
[^2]: To say "extending the ray" is a bit of a misnomer. "vector" is more accurate in this situation but "ray" sounds better.
[^3]: This definition is slightly different than what is in the implementation because our player angle won't always be between 0 and 𝜏. The coordinate system will also be vertically flipped.