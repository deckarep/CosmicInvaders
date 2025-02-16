# Cosmic Invaders

<p align="center">
    <img src="https://raw.githubusercontent.com/deckarep/CosmicInvaders/refs/heads/main/screenshot.png">
</p>

These assets come from an old Allegro ~4.2 game and are in zlib compressed format. Two types of bitmap files
exist: `.mz` and `.sz` files. The `.mz` variant are just simple bitmap graphics usually containing no animation
frame data and are just meant to largely convey RGB24 static images, such as a game background.

The `.sz` variant is meant to utilize Allegro's `sub_bitmap` feature and treats the asset as having multiple
frames of data as an RGB24 animated/multi-frame set of images.

The good news is, both file types can be treated as a single bitmap at least for the purpose of viewing the
files and properly extracting them.

So far, this code will also knock out the two key colors that this particular collection of assets use.

In order to process these files `zlib` must be used to properly deal with the fact that they are compressed.
The way these assets were figured out is by reverse engineering the original game asset using Binary Ninja.

To decompress and generate the `.png` equivalent assets just do: `zig build run` or for zigup users:
`zigup run master build run`

# Note and License

The original game was **not** built by me and was created circa 2006. If you are adept at coding and can
figure out how I extracted the assets then you'll have access to the original game assets! If not, don't ask.

Aside from the game assets, this version is a **fully clean-room, developed implementation** of how I think
the code behaves from observation of the original game. My version of this game, written in Zig is
protected by the `AGPL-3.0` license. Additionally, while I intend to create a close working clone, I will
not be so strict on details and am mostly concerned with capturing the spirit of the original game. I might
even diverge or change some aspects of the game such as the graphics, enemies, sound, music, etc.

# Original

- [ ] On start game, player starts with 550 money, 25 health points
- [ ] Weapons
    - [ ] Lazer Canon Turret = 140 - simply fires projectile up
    - [ ] Missle Battery = 350 - fires a heat seeking, exploding missle
    - [ ] Spark Tower = 550 - emits a catastrophic spark of electricity
- [ ] On game over, show GAME OVER banner, WAVES DEFEATED: <howmany>
- [x] Max of 12 invaders per row
- [ ] Every level, a new set of invaders is spawn in symmetrical formation
- [ ] On game over screen, everything is rendered in monochrome greyscale except banner
- [x] Hit on invader makes it flash white, invader now becomes red
- [x] Between waves, all player's buildings remain
- [x] On building hit, show a single dust cloud
- [x] When building is below X percent, show repeated dust clouds
- [ ] Buildings cannot overlap on user placement, if overlapped render as red and don't allow placing it
- [ ] When an invader is hit, his framerate speeds up temporarily to illustrate injury (faster pulsing)
- [ ] Each new building costs more than the last
- [ ] BOSS FIGHT: Every 5 levels (confirm this), a boss shows up drops red balls, green bubble with red eye
      Invaders will fly in circular motion around it, protecting it
- [ ] More notable settings and increase factors can be found here: `data/strings.txt`
