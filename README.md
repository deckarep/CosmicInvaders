# Cosmic Invaders

<p align="center">
    <img src="https://raw.githubusercontent.com/deckarep/CosmicInvaders/refs/heads/main/screenshot.png">
</p>

These assets come from an old Allegro ~4.2 game and are in zlib compressed format. Two types of bitmap files
exist: `.mz` and `.sz` files. The `.mz` variant are just simple bitmap graphics usually containing no animation
frame data and are just meant to largely convey RGB24 static images.

The `.sz` variant is meant to utilize Allegro's sub_bitmap feature and treats the asset as having multiple
frames of data usually used as RGB24 animated/multi-frame images.

The good news is, both file types can be treated as a single bitmap at least for the purpose of viewing the
files and properly extracting them.

So far, this code will also knock out the two key colors that this particular collection of assets use.

In order to process these files `zlib` must be used to properly deal with the fact that they are compressed.
The way these assets were figured out is by reverse engineering the original game asset using Binary Ninja.

To decompress and generate the `.png` equivalent assets just do: `zig build run`

# Note

The original game was not built by me and is circa 2006. If you are adept at coding and can either
read this code and port it, or run this code then you'll have access to the assets! If not, don't ask.