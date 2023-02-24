+++
title = "Write a 2KB FPS with Rust"
description = "Learn about raycasting and discover some elegant math by creating a tiny 4KB game with Rust."
date = "2023-02-18"
draft = true
math = true
useRelativeCover = true
cover = "cover.png"
+++

## Introduction
In this post we'll uncover an elegant algorithm and create tiny first-person "game" with Rust.
My goal here is to show how something that looks complicated can be broken down into simple pieces.
If I've done my job right, it should feel like you've *discovered* how to make the game.

First I'll walk you through how the algorithm behind the game works, then we'll write it out line by line.
I tried to make this as accessible as possible but a healthy understanding of programming as well as Rust and trigonometry will help.

Here's a quick preview of what we'll be making:

{{< loopingvideopreview src="preview.webm" type="video/webm" scale=2 >}}

My first experience with games like this (though I didn't know at the time), was in middle school with games like {{< newtabref href="https://www.ticalc.org/archives/files/fileinfo/360/36062.html" >}}zDoom{{</ newtabref >}} on my calculator.
ZDoom (while probably not as fun as {{< newtabref href="https://www.ticalc.org/archives/files/fileinfo/336/33606.html" >}}snake{{</ newtabref >}}), was fascinating to me because it could (kind of) create the illusion of perspective, something I thought only "real" games could do.

{{< figure src="zdoom.png" position="center" >}}

zDoom was only an imitation of the original game Doom, in reality it was much closer to Doom's predecesor, Wolfenstein 3D.

### Wolfenstein 3D
Most articles and videos about ray casting start with Wolfenstein 3D, and for good reason.
Famously, {{< newtabref href="https://en.wikipedia.org/wiki/Wolfenstein_3D" >}}Wolfenstein 3D{{</ newtabref >}}, released in 1992, was one of the first 3D first-person games to run on consumer PCs.
Back then, computers didn't have hardware 3D acceleration, let alone dedicated graphics cards, so how was this done?

{{< figure src="https://upload.wikimedia.org/wikipedia/en/6/69/Wolf3d_pc.png" position="center" caption="A screenshot from wolfenstein 3D" >}}

Well, I should have said {{< newtabref href="https://en.wikipedia.org/wiki/2.5D" >}}*pseudo*-3D{{</ newtabref >}} because no part of the game actually ran in three-dimensions.
The core of the game was an algorithm called ray casting[^1], a process of projecting a 2D game into a 3D perspective.

All the game entities were located at simple x and y positions on the map and could not move vertically.
Upon release, I'm sure that this didn't matter, but with our current standards it definitely shows it's age.
The player could not look up or down, let alone crouch or jump.

{{< figure src="wolfenstein-map.png" position="center" caption="A top-down view of the first level of Wolfenstein 3D" >}}

To add to that, all the levels were composed of single floors of buildings with no windows.
Also, all walls were perfectly straight with corners placed at even intervals (something that will definitely not come up later).
These design features were all put here because of some of the essential restrictions of it's simple ray casting algorithm.

## The Algorithm
### The Basics
At the most fundamental level, ray casting depends on the simple fact that objects that are further away from us appear smaller while objects that are closer appear larger.
Ray casting uses this fact to draw draw walls at shorter heights the further away they from the player and at taller heights the closer they are.

Just this simple idea alone creates a convincing illusion of depth and allows us to move our player around just as if it were being rendered in actual 3D.

Ray casting *works* by tracing a path from the player to the closest wall for each column in the player's view.
It then records the distances of each path before converting it into the height of a wall and drawing it on screen as a vertical line.

{{< figure src="figure-overview.svg" position="center" >}}

From what we know so far about the raycasting algorithm we can deduce that we will need to:

 - Cast a ray from the player and stop at the nearest wall
 - Calculate the distance from the player to that nearest wall
 - Convert that distance into the height of a wall and draw it on screen
 - Repeat that for each column on screen ↺

### Digging Deeper
The hardest part of this is "cast a ray from the player and stop at the nearest wall".
This seems simple on paper but in practice it can be {{< newtabref href="https://en.wikipedia.org/wiki/Collision_detection" >}}pretty difficult{{</ newtabref >}}.
If you had to come up with a ray casting implementation yourself, how would you approach it?

{{< figure src="figure-question.svg" position="center" caption="The Intersection Problem" >}}

The first idea most people would probably have is to repeatedly extend the ray[^2] a small amount and stop when it hits a wall.
This is problematic because when extending the ray we might skip over the wall and miss it entirely.
If the ray does hit the wall correctly it will have very low accuracy because it won't know exactly where the wall started, just that it landed in one.

{{< figure src="figure-naive.svg" position="center" caption="The Naive Solution" >}}

What we need is to find a way that we can *guarantee* that the ray will intersect with a wall and that it will stop right on the border of that wall.
In math land we might be able to do this by extending the ray an infinitely small distance infinitely many times.
Sadly, we're not in math land so we can't do that.

The solution to this, as you might have guessed from the foreshadowing earlier, is to align all the walls to a grid. 
If we know that the walls fall on predictable intervals we can calculate a reliable distance to extend our ray each time.

{{< figure src="figure-solution.svg" position="center" caption="Notice a pattern?" >}}

But how do we calculate this distance?

If you get out some grid paper and sketch out the lines between the player to various walls you'll start to notice some patterns.
"Ray extensions" on their way to walls that fall on horizontal grid lines all share a common width while "ray extensions" that land on vertical grid lines all share a common height.

We can calculate these shared "extension widths" and heights then extend them to get the closest wall we intersect on a vertical grid line and the closest wall on we intersect on a horizontal grid line.
After that we can make the "official" distance to the wall the shorter of the two because that's the one it intersected with first.

I admit this is a bit confusing so I'll explain what this means in more depth:

### Horizontal Intersections
This figure is interactive, try dragging around the player!

{{< geogebra
    file="ggb/horizontal.ggb"
    name="horizontal"
    caption="Notice how only the *width* between extensions changes when the player moves."
    coords="-2.78, 13.18, -4.48, 7.48" >}}

In horizontal wall intersections the height between "extensions" is always one, while the width between extensions can be derived from the angle of the ray.

You can see this by looking at the diagram, the width between Z and Y is the same as the width between X and Y, and the height between all points is one.
Using some simple trigonometry we can find the width between horizontal grid intersections from the angle of the player.
I'm going to save you the work and just give you the definition:

$$ \Delta H = \begin{cases} 1 &\text{if } \pi > \theta \ge 0  \text{ (facing up)} \\\ -1 &\text{if } \tau > \theta \ge \pi \text{ (facing down)} \end{cases} $$
$$ \Delta W = \frac{\Delta H}{\tan(\theta)} $$

### Vertical Intersections
This figure is also interactive, try dragging around the player!

{{< geogebra
    file="ggb/vertical.ggb"
    name="vertical"
    caption="Here the *height* between extensions changes while the width stays the same."
    coords="-3.097, 8.238, 2.274, 10.769"
>}}

Vertical grid intersections are the same as horizontal grid intersections, just rotated 90°.
In vertical grid intersections the *width* between our "ray extensions" is the constant while the *height* is created from the angle of the ray.
Like last time, I'm going to skip ahead and define our variables for you.

$$ \Delta W = \begin{cases} 1 &\text{if } \pi/2 > \theta > -\pi/2 \text{ (facing right)} \\\ -1 &\text{if } 3\pi/4 > \theta > \pi/2 \text{ (facing left)} \end{cases} $$
$$ \Delta H = \Delta W * \tan(\theta) $$

### Summary
Now that we know pretty much exactly how we'll do this we can compile it into a more detailed step-by-step list for our program to execute on each frame.

For each vertical line on screen:
1. Find the angle for the ray from the player's angle and field of view.
2. Determine the distance to the nearest wall that the ray intersects with:
   - Repeatedly extend the ray between horizontal grid lines, stopping when it hits a wall.
   - Now do the same again, but stop on vertical grid lines instead.
   - Choose the closest of those two intersections for the distance to the wall.
3. Convert that distance into the height of a wall on screen and draw it.

## Implementation
Now that we understand how the underlying algorithm works we can write a program that implements it using Rust and WASM-4.

Wait why WASM-4?
The official answer is because we need a way for our program to accept user input and draw to the screen.
The real answer is because I like it a lot.

{{< newtabref href="https://wasm4.org" >}}WASM-4{{</ newtabref >}} is a tiny game engine which runs WebAssembly (`.wasm`) files.
Most compiled programming languages (C, C++, Rust, Zig, etc.) can compile to WebAssembly which means games for WASM-4 can be written in any of those languages!
WASM-4 is *extremely* minimal, the "4" in "WASM-4" is there because you can only draw four colors on screen at once.

{{< mermaid >}}
graph LR
    source[lib.rs] --> compiler[rustc] --> wasm
    subgraph wasm4[WASM-4]
        wasm[game.wasm]
    end
    wasm4--> player[Player]
{{< /mermaid >}}

WASM-4 will let us create *tiny* games because it provides a simple platform for us to build our game off of.
WASM-4 handles windowing, graphics rendering, and gamepad input, we have to do everything else.

Here are the specs for the WASM-4 "fantasy console" from the website:

 >  - Display: 160x160 pixels, 4 customizable colors, updated at 60 Hz.
 >  - Memory: 64 KB linear RAM, memory-mapped I/O, save states.
 >  - Cartridge Size Limit: 64 KB.
 >  - Input: Keyboard, mouse, touchscreen, up to 4 gamepads.
 >  - Audio: 2 pulse wave channels, 1 triangle wave channel, 1 noise channel.
 >  - Disk Storage: 1024 bytes.

If you know a bit about computer hardware you'll know this is an *incredibly* restrictive environment for a game to run in.
That's the fun of it though, seeing how much you can cram into 160x160px, 4 colors and 64KB of disk space.
If you want to see what people are able to create with it, check out the {{< newtabref href="https://wasm4.org/play" >}}WASM-4 site{{</ newtabref >}} for some very impressive games (including a flight simulator!).

I'll probably make a more in-depth blog post on WASM-4 in the future, but for now this explanation should be good enough for our case.
All you need to run WASM-4 games is to [download and install the minimal runtime](https://wasm4.org/docs/getting-started/setup).

### Project Setup
Because WASM-4 runs WebAssembly files we have to configure our project to create one.

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
We also import {{< newtabref href="https://crates.io/crates/libm" >}}`libm`{{< /newtabref >}}, a library which will provide us some `no_std` implementations of functions we need like `sin`, `tan`, and `floor`. (more on that later)

In our crate configuration file named `.cargo/config.toml` lets add:
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
This will tell cargo to use WebAssembly by default and to pass some flags to rustc which tell our program to reserve some memory for the game.

Now, lets add some simple boilerplate to our source file `src/lib.rs`:
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
Here's a little explanation of the code here for those who aren't familiar with Rust or WASM-4:

 - `#![no_std]` prohibits the program from accessing the Rust standard library.
This is essential in almost all WASM-4 games because the standard library is large and might put our game over the 64KB size limit.

 - {{< newtabref href="https://wasm4.org/docs/reference/memory#gamepads" >}}`GAMEPAD1`{{</ newtabref >}} is a pointer to the current state of the first gamepad (the arrow keys in our case).
The runtime will update this section of memory with the state of our gamepad (keyboard) on each frame.

 - The constants `BUTTON_LEFT` through `BUTTON_DOWN` describe the bits in the gamepad which describe each button.
We can use these to check if `GAMEPAD1` says that a button is down, that's what we're doing when we call `*GAMEPAD1 & BUTTON_UP != 0`.

 - `extern "C" fn vline` links our game to an external function WASM-4 provides for us, {{< newtabref href="https://wasm4.org/docs/reference/functions/#vlinex-y-len" >}}`vline`{{</ newtabref >}}.
`vline` draws a vertical line on the window at `x`, `y` and extends it down `len` pixels.

 - `#[panic_handler] fn phandler` is a little bit of boilerplate that Rust requires we provide if we choose to use `#![no_std]`. This function will run when the program panics. Because WASM-4 is such a restrictive environment the only thing we can really do is call `wasm32::unreachable()`.

 - {{< newtabref href="https://wasm4.org/docs/reference/functions/#update-" >}}`fn update`{{</ newtabref >}} is the main entrypoint into our program, WASM-4 calls this function on each frame.

To compile our game we can build it just like any other crate:
```sh
 $ cargo build --release
```

And to run it we can use `w4 run-native`:
```sh
 $ w4 run-native target/wasm32-unknown-unknown/release/raycaster.wasm
```

This will launch an empty window, and if we press the up arrow on the keyboard a vertical line will appear in all its green gameboy-ish glory.

{{< figure src="screenshot-one.png" position="center" caption="It's alive!" >}}

One thing I like to do in a situation like this commands we're going to call often is to put these commands in a simple `Makefile` so we don't have to re-type the commands or over use the up arrow.
After that all we have to do to build and run the program is type `make run`.
```makefile
all:
    cargo build --release

run: all
    w4 run-native target/wasm32-unknown-unknown/release/raycaster.wasm
```

Great, now that we've got the workflow down we can get to writing the game.

### Storing The Map
The simplest way to store the map is a grid of wall or no wall. One way we could store the map as `[[bool; WIDTH]; HEIGHT]` and access it through `map[][]`.
Storing the map this way wouldn't be very elegant because we'd have to type out each cell individually as a `true` or `false`.

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

The more difficult thing about this way of storing the map is accessing it.
In order to do this we have to write a function which first indexes into the row then into the specific column by masking and then shifting the row.
This post is already long as it is so for the sake of time I'm not going to go in depth about how the X coordinate lookup works in this function.
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

One thing to note about `coord_contains_wall` is that the Y axis is "flipped" meaning $ y = 0 $ is at the top.
This is not only faster but reflects the {{< newtabref href="http://www.e-cartouche.ch/content_reg/cartouche/graphics/en/html/Screen_learningObject3.html" >}}coordinate system software most commonly uses{{</ newtabref >}}.

### Maintaining Game State
The map stays constant throughout the runtime of the program, but the player's position and angle changes.
Because WASM-4 calls `update` on each frame the only way to store our game state across frames is via something like Rust's {{< newtabref href="https://doc.rust-lang.org/reference/items/static-items.html">}}`static mut`{{</ newtabref >}}.
Because `static mut` is {{< newtabref href="https://doc.rust-lang.org/book/ch19-01-unsafe-rust.html" >}}`unsafe`{{</ newtabref >}} we should consolidate our game logic and state in a single `struct` so we minimize the number of times we modify our state throught `static mut`.

Only three variables are required to describe the player's view: the X and Y position and viewing angle.
```rust
struct State {
    player_x: f32,
    player_y: f32,
    player_angle: f32,
}    
```

Lets put the `State` in memory:

```rust
static mut STATE: State = State {
    player_x: 1.5,
    player_y: 1.5,
    player_angle: 0.0,
};
```
 > *`player_x` and `player_y` are both initially set at 1.5 so the player starts in the center of a cell and not inside a wall.*

Not only is accessing `State` `unsafe` behavior, most interactions with WASM-4 are. (dereferencing raw pointers, calling external functions, etc.)

If we consolidate `unsafe` behavior into `fn update` and game logic into `State` we isolate our state and give some structure to our program.
It gives us a pretty clear line: `unsafe` I/O in `fn update` which calls game logic in `State`.

{{< mermaid >}}
flowchart
    subgraph unsafe
        w[WASM-4] --> f[fn update]
    end

    f --> u[struct State]
{{</ mermaid >}}

### Moving the Character
One of the easier parts of this game is moving the character.
Because accessing `STATE` from outside is `unsafe`, lets create a method inside of `State` to move the character and pass in the inputs on each frame.

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

If you've ever moved a player in a game and know some basic trigonometry this should all look familiar.
Note that calls to `sinf` are negative, this is because our Y-axis is flipped.

If the player is asking us to move the player forwards or backwards we modify the player's x and y positions based on the `cosf` and `sinf` values of the player's angle multiplied by a constant `STEP_SIZE`.

Just for you, I'll give you a magic number you can change later if you'd like:
```rust
const STEP_SIZE: f32 = 0.045;
```

The last thing that we need to make this function work is to import `cosf` and `sinf` from `libm`.

```rust
use libm::{cosf, sinf};
```

 > *Why `sinf/cosf` and not `sin/cos`? This naming convention comes from C where `sin/cos` handles doubles and `sinf/cosf` handles floats.*
 > *In Rust's implementation `libm` this means `fn cos(x: f64) -> f64` and `fn cosf(x: f32) -> f32`.*
 > *We're using `f32` and not `f64` because it saves space and we don't need the precision.*

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

### Horizontal Intersections
Before we draw the walls on the screen we need to implement the core of our algorithm, horizontal and vertical intersection checks.

### Vertical Intersections
Lets implement vertical intersections too before drawing the walls.

### Creating The View
So far we haven't written anything we can interact with.
Well we can *act* on it (move the character), but we can't see what we're doing.
Lets try drawing the walls.

If you remember from the [summary](#summary), we have to draw vertical lines for every column on the window.

We can split this up into two separate jobs: getting the heights of the lines and actually drawing them on the screen.
Why not do this all at once?
Well, `vline` is `unsafe` so lets keep it in `fn update`.
Getting the player's view is game logic and should be kept in `State` where it can avoid using `unsafe` to access `STATE`.

Lets do this by defining `State::get_view` which returns a list of all the wall heights.
Then, on each frame, we can call `State::get_view` from `fn update` and draw all of those vertical lines we just calculated.

`State::get_view` will work by going through each vertical line on screen (160), calculating the angle offset from the player's point of view, then finding the distance to the closest horizontal and vertical intersections with walls in the ray's path.
Then it compares the two distances and turns the smaller of the two into the height of a wall.

I know that sounds complicated so lets go ahead and "scaffold out" what that looks like:

Then, lets create some constants which define our player's perspective.
```rust
const FOV: f32 = PI / 2.7; // The player's field of view.
const HALF_FOV: f32 = FOV * 0.5; // Half the player's field of view.
const ANGLE_STEP: f32 = FOV / 160.0; // the angle between each ray.
const WALL_HEIGHT: f32 = 100.0; // A magic number.
```

Now, lets add `get_view` to our existing `State` impl block.
```rust
impl State {
    /// Returns 160 wall heights from the player's perspective.
    pub fn get_view(&self) -> [i32; 160] {
        // The player's FOV is split in half by their viewing angle.
        //
        // in order to get the ray's starting angle we must
        // add half the FOV to the player's angle to get
        // the edge of their FOV.
        let starting_angle = self.player_angle + HALF_FOV;

        let mut walls = [0; 160];

        for (idx, wall) in rays.iter_mut().enumerate() {
            // `idx` is what number ray we are, `wall` is
            // a mutable reference to a value in `walls`.
            let angle = starting_angle - idx as f32 * ANGLE_STEP;

            // Get both the closest horizontal and vertical wall
            // intersections for this angle.
            let h_dist = self.horizontal_intersection(angle);
            let v_dist = self.vertical_intersection(angle);

            // Get the minimum of the two distances and
            // "convert" it into a wall height.
            *wall = (WALL_HEIGHT / f23::min(h_dist, v_dist)) as i32;
        }

        wall
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

    // go through each column on screen and draw walls in the center.
    for (x, wall_height) in STATE.get_view().iter().enumerate() {
        vline(x as i32, 80 - (wall_height / 2), *wall_height as u32);
    }
}
```

## Getting A New Perspective
When playing the game you might notice that everything looks... wrong.
Walls seem to bend away from you as if you were looking through a fisheye lens.

{{< figure src="fisheye.png" position="center" caption="This is what it looks like when facing a wall straight on." >}}

## Adding Some Depth

{{< figure src="depth.png" position="center" caption="Looks better, right!" >}}

## Making It Smaller!

## Somehow Even Smaller?!

## Conclusion
[^1]: In this post I call specific the ray casting algorithm used in games like Wolfenstein 3D "ray casting" for the sake of brevity. This is slightly innacurrate as ray casting has a more general meaning in the field of graphics. See the [Wikipedia Article](https://en.wikipedia.org/wiki/Ray_casting).
[^2]: To say "extending the ray" is a bit of a misnomer. "vector" is more accurate in this situation but "ray" sounds better.
