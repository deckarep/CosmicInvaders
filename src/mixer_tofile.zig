const std = @import("std");
const c = @import("cdefs.zig").c;

// Reference tracks: https://robricketts.bigcartel.com/product/pretty-tony-fix-it-in-the-mix

// Question: How much of this can be done at comptime?
// Can we take a text pattern => in-memory mixed waveform all at comptime?
// We could if our samples were not loaded as files but embeded binary data.
const SAMPLE_FLDR = "data/drum_samples/";
const LOOP_DURATION = 30;
const SAMPLE_RATE = 44100; // Standard audio sample rate
const BUFFER_SIZE = 44100; // 1 second of audio data (44100 samples)
const CHANNELS = 1; // Mono audio
const BIT_DEPTH = 16; // 16-bit audio

const Track = struct {
    timing: []const u8, // "x---|x---|x---|x-x-"
    name: []const u8, // The instrument name (e.g., "kick")
    volume: f32 = 1.0, // Volume multiplier, 1.0 is default when unspecified.
    sample: ?*c.Wave, // Loaded WAV file
};

const Sequence = struct {
    Artist: []const u8,
    Song: []const u8,
    Year: ?u16 = null, //optional for now.
    Bpm: u8,
    TrackLayers: []const Track,
};

// 808 set hardcoded.
var kick: c.Wave = undefined;
var snare: c.Wave = undefined;
var hihat_open: c.Wave = undefined;
var hihat_closed: c.Wave = undefined;
var clap: c.Wave = undefined;
var cowbell: c.Wave = undefined;
var tomhi: c.Wave = undefined;
var tomlow: c.Wave = undefined;
var rim: c.Wave = undefined;

// Linn set hardcoded.
var linn_chhs: c.Wave = undefined;
var linn_chhl: c.Wave = undefined;
var linn_chh: c.Wave = undefined;
var linn_cgh: c.Wave = undefined;
var linn_cgl: c.Wave = undefined;
var linn_cb: c.Wave = undefined;
var linn_cl: c.Wave = undefined;
var linn_sd: c.Wave = undefined;
var linn_sdl: c.Wave = undefined;
var linn_kick: c.Wave = undefined;

// TODO:
// Computer Power - Jamie Jupitor (Egyptian Lover actually)

// Thriller - Michael Jackson 16 beats - 138
// Gross, this is wrong...doesn't sound right.
const seqTH = Sequence{
    .Song = "Thriller",
    .Artist = "Michael Jackson",
    .Bpm = 118,
    .TrackLayers = &.{
        Track{ .timing = "x-x-|x-xx|x-x-|x-x-|x-x-|x-xx|x-x-|x-x-", .name = "hi-hat", .volume = 0.25, .sample = &linn_chh },
        Track{ .timing = "----|----|---x|---x|----|----|---x|---x", .name = "hi-hat-long", .volume = 0.25, .sample = &linn_chhl },
        Track{ .timing = "---x|--x-|----|----|---x|--x-|----|----", .name = "conga-high", .volume = 0.25, .sample = &linn_cgh },
        Track{ .timing = "----|x---|x--x|--x-|----|x---|x--x|--x-", .name = "conga-low", .volume = 0.25, .sample = &linn_cgl },
        Track{ .timing = "---x|---x|----|----|---x|---x|----|----", .name = "cowbell", .volume = 0.50, .sample = &linn_cb },
        Track{ .timing = "----|----|----|x---|----|----|----|x---", .name = "clap", .volume = 0.5, .sample = &linn_cl },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "snare", .sample = &linn_sd },
        Track{ .timing = "x---|x---|x---|x---|x---|x---|x---|x---", .name = "kick", .sample = &linn_kick },
    },
};

// ✅ Burning up - Madonna - 16 beats - 139 bpm
const seqBU = Sequence{
    .Song = "Burning Up",
    .Artist = "Madonna",
    .Bpm = 139,
    .TrackLayers = &.{
        // NOTE: converted to 32 steps even though it's just duplicated.
        Track{ .timing = "x-x-|x-x-|x-x-|x-x-|x-x-|x-x-|x-x-|x-x-", .name = "hi-hat-short", .volume = 0.25, .sample = &linn_chhs },
        Track{ .timing = "----|----|----|---x|----|----|----|---x", .name = "hi-hat", .volume = 0.1, .sample = &linn_chh },
        Track{ .timing = "----|x-x-|----|x---|----|x-x-|----|x---", .name = "clap", .volume = 0.5, .sample = &linn_cl },
        Track{ .timing = "----|x-x-|----|x---|----|x-x-|----|x---", .name = "snare-low", .sample = &linn_sdl },
        Track{ .timing = "x---|x---|x---|x-x-|x---|x---|x---|x-x-", .name = "kick", .sample = &linn_kick },
    },
};

// ✅ Clear - Cybotron - 32 beats - 125bpm
const seqCL = Sequence{
    .Song = "Clear",
    .Artist = "Cybotron",
    .Bpm = 125,
    .TrackLayers = &.{
        Track{ .timing = "x--x|--x-|--x-|----|x---|--x-|--x-|x---", .name = "bd", .sample = &kick },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "snare", .sample = &snare },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "clap", .sample = &clap },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "oh", .sample = &hihat_open },
        Track{ .timing = "xxxx|----|xxxx|----|xxxx|----|xxxx|----", .name = "ch", .sample = &hihat_closed },
    },
};

// ✅ 19 - Paul Hardcastle - 32 beats - 118bpm
const seq19 = Sequence{
    .Song = "19",
    .Artist = "Paul Hardcastle",
    .Bpm = 118,
    .TrackLayers = &.{
        Track{ .timing = "xx-x|---x|--x-|x---|xx-x|---x|--x-|x---", .name = "bd", .sample = &kick },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x-xx", .name = "sd", .sample = &snare },
        Track{ .timing = "x--x|--x-|--xx|x---|x--x|--x-|--x-|-x--", .name = "rs", .sample = &rim },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x-xx", .name = "cp", .sample = &clap },
        Track{ .timing = "xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx", .name = "ch", .sample = &hihat_closed },
    },
};

// ✅ Hangin' on a String - Loose Ends - 32 beats - 105bpm
const seqHOT = Sequence{
    .Song = "Hangin' on a String",
    .Artist = "Loose Ends",
    .Bpm = 105,
    .TrackLayers = &.{
        Track{ .timing = "x---|--x-|x---|----|x---|--x-|x---|----", .name = "bd", .sample = &kick },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "sd", .sample = &snare },
        Track{ .timing = "---x|----|----|x---|----|----|----|----", .name = "rs", .sample = &rim },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "cp", .sample = &clap },
        Track{ .timing = "----|----|--xx|xxx-|----|----|----|----", .name = "cb", .volume = 0.25, .sample = &cowbell },
        Track{ .timing = "x---|----|----|----|----|----|x---|----", .name = "oh", .sample = &hihat_open },
        Track{ .timing = "---x|x-x-|x--x|x-x-|x--x|x-x-|-x-x|xxx-", .name = "ch", .sample = &hihat_closed },
    },
};

// ✅ Fix in the Mix - Prety Tony 32 beats - 129bpm
const seqFITM = Sequence{
    .Song = "Fix in the Mix",
    .Artist = "Pretty Tony",
    .Bpm = 129,
    .TrackLayers = &.{
        Track{ .timing = "x---|--x-|--x-|-x--|x---|--x-|----|----", .name = "kick", .sample = &kick },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "snare", .sample = &snare },
        Track{ .timing = "x-xx|x-xx|x-xx|xxxx|x-xx|x-xx|x-xx|xxxx", .name = "ch", .sample = &hihat_closed },
    },
};

// ✅ Egypt Egypt 32 beats - 127 - Close, missing accent programming. How to do?
const seqEE = Sequence{
    .Song = "Egypt Egypt",
    .Artist = "Egyptian Lover",
    .Bpm = 127,
    .TrackLayers = &.{
        Track{ .timing = "x---|--x-|--x-|-x--|x---|--x-|--x-|--x-", .name = "kick", .sample = &kick },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "snare", .sample = &snare },
        Track{ .timing = "x-x-|xxx-|x-xx|-xx-|x-x-|xxx-|x-xx|-xx-", .name = "cowbell", .volume = 0.55, .sample = &cowbell },
        Track{ .timing = "xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx", .name = "closed_hat", .volume = 0.75, .sample = &hihat_closed },
        // Accent track, applies to all instruments, and is really just an alternative volume modifier in the range of: 1.0 - 2.0
        // BUG: Currently too high of a .volume will crash with integer overflow so I need to fix that at some point.
        // NOTE: Though subtle, it makes a difference and gives more character to the sequence as a whole.
        Track{ .timing = "x-xx|x-xx|x-xx|xxxx|x-xx|x-xx|x-xx|x-xx", .name = "accent", .volume = 1.25, .sample = null },
    },
};

// ✅ Part 2 (Egypt Egypt) ChatGPT AI beat attempt
//Pattern{ .timing = "x---|--x-|x--x|-x--|x---|--x-|--x-|--x-", .name = "kick", .sample = &kick }, Pattern{ .timing = "----|x---|----|x---|----|x-x-|----|x---", .name = "snare", .sample = &snare }, Pattern{ .timing = "x-x-|xxx-|x-xx|-xx-|x-x-|x-xx|x-x-|-xx-", .name = "cowbell", .volume = 1.0, .sample = &cowbell }, Pattern{ .timing = "xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|----", .name = "closed_hat", .volume = 0.75, .sample = &hihat_closed },

// ✅ Jam on It
const seqJOI = Sequence{
    .Song = "Jam On It",
    .Artist = "Newcleus",
    .Bpm = 116,
    .TrackLayers = &.{
        Track{ .timing = "x---|---x|-xx-|--x-|xx--|---x|-xx-|x-x-", .name = "kick", .sample = &kick },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "snare", .sample = &snare },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "clap", .sample = &clap },
        Track{ .timing = "xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx", .name = "closed_hat", .volume = 0.75, .sample = &hihat_closed },

        // Track{ .timing = "x---|--x-|x-xx|--x-|xx-x|---x|-x-x|x-x-", .name = "kick", .sample = &kick },
        // Track{ .timing = "----|x--x|----|x---|----|x--x|----|x---", .name = "snare", .sample = &snare },
        // Track{ .timing = "----|x---|--x-|x---|----|x-x-|----|x---", .name = "clap", .sample = &clap },
        // Track{ .timing = "xxxx|xxxx|xxx-|xxxx|xxxx|xxxx|xxxx|----", .name = "closed_hat", .volume = 0.75, .sample = &hihat_closed },

        // Track{ .timing = "x---|--x-|--x-|x---|x---|--x-|x--x|--x-", .name = "kick", .sample = &kick },
        // Track{ .timing = "----|x---|--x-|x---|----|x-x-|----|x---", .name = "snare", .sample = &snare },
        // Track{ .timing = "----|x---|x--x|x---|----|x---|x--x|----", .name = "clap", .sample = &clap },
        // Track{ .timing = "xxxx|xxxx|xx-x|xxxx|xxxx|xx-x|xxxx|xxxx", .name = "closed_hat", .volume = 0.75, .sample = &hihat_closed },
    },
};

// ✅ Planet Rock.
const seqPR = Sequence{
    .Song = "Planet Rock",
    .Artist = "Afrikaa Bambata",
    .Bpm = 127,
    .TrackLayers = &.{
        Track{ .timing = "x---|--x-|----|----|x---|--x-|--x-|----", .name = "kick", .volume = 1.0, .sample = &kick },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "snare", .volume = 1.0, .sample = &snare },
        Track{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "clap", .volume = 1.0, .sample = &clap },
        Track{ .timing = "x-x-|x-xx|-x-x|x-x-|x-x-|x-xx|-x-x|x-x-", .name = "cowbell", .volume = 0.75, .sample = &cowbell },
        Track{ .timing = "x-xx|x-xx|x-xx|xxxx|x-xx|x-xx|x-xx|xxxx", .name = "closed_hat", .volume = 0.75, .sample = &hihat_closed },
    },
};

// Test: no mans land...can we do a comptime c.Wave?
// Not without some magic, Raylib uses the heap when setting up a Wave (even from memory)
// const playComptimeWaveInstead = true;
// const tempGlobalBufSize = 1024 * 1024;
// var tempGlobalBuf: [tempGlobalBufSize]i16 = undefined;
// const loopA = generateSequence(
//     &seqPR,
//     LOOP_DURATION,
//     seqPR.Bpm,
//     &tempGlobalBuf,
//     tempGlobalBufSize,
// );

fn loadSamples() void {
    // Load 808 drum samples
    kick = c.LoadWave(SAMPLE_FLDR ++ "808/bass-drum.wav");
    snare = c.LoadWave(SAMPLE_FLDR ++ "808/snare.wav");
    hihat_closed = c.LoadWave(SAMPLE_FLDR ++ "808/hihat-closed.wav");
    hihat_open = c.LoadWave(SAMPLE_FLDR ++ "808/hihat-open.wav");
    clap = c.LoadWave(SAMPLE_FLDR ++ "808/clap.wav");
    cowbell = c.LoadWave(SAMPLE_FLDR ++ "808/cowbell.wav");
    tomhi = c.LoadWave(SAMPLE_FLDR ++ "808/tom-hi.wav");
    tomlow = c.LoadWave(SAMPLE_FLDR ++ "808/tom-low.wav");
    rim = c.LoadWave(SAMPLE_FLDR ++ "808/rim-shot.wav");

    // Load Linn drum samples
    linn_chhs = c.LoadWave(SAMPLE_FLDR ++ "linn/chhs.wav");
    linn_chhl = c.LoadWave(SAMPLE_FLDR ++ "linn/chhl.wav");
    linn_chh = c.LoadWave(SAMPLE_FLDR ++ "linn/chh.wav");
    linn_cgh = c.LoadWave(SAMPLE_FLDR ++ "linn/congah.wav");
    linn_cgl = c.LoadWave(SAMPLE_FLDR ++ "linn/congal.wav");
    linn_cb = c.LoadWave(SAMPLE_FLDR ++ "linn/cowb.wav");
    linn_cl = c.LoadWave(SAMPLE_FLDR ++ "linn/clap.wav");
    linn_sdl = c.LoadWave(SAMPLE_FLDR ++ "linn/sdl.wav");
    linn_sd = c.LoadWave(SAMPLE_FLDR ++ "linn/sd.wav");
    linn_kick = c.LoadWave(SAMPLE_FLDR ++ "linn/kick.wav");
}

fn unloadSamples() void {
    // Unload 808
    defer c.UnloadWave(kick);
    defer c.UnloadWave(snare);
    defer c.UnloadWave(hihat_open);
    defer c.UnloadWave(hihat_closed);
    defer c.UnloadWave(clap);
    defer c.UnloadWave(cowbell);
    defer c.UnloadWave(tomhi);
    defer c.UnloadWave(tomlow);
    defer c.UnloadWave(rim);

    // Unload Linn
    defer c.UnloadWave(linn_chhs);
    defer c.UnloadWave(linn_chhl);
    defer c.UnloadWave(linn_chh);
    defer c.UnloadWave(linn_cgl);
    defer c.UnloadWave(linn_cgh);
    defer c.UnloadWave(linn_cl);
    defer c.UnloadWave(linn_cb);
    defer c.UnloadWave(linn_sdl);
    defer c.UnloadWave(linn_sd);
    defer c.UnloadWave(linn_kick);
}

inline fn startTime() !std.time.Instant {
    const s = try std.time.Instant.now();
    return s;
}

inline fn endTimePrint(name: []const u8, start: std.time.Instant) !void {
    const endTime = try std.time.Instant.now();
    const elapsed = endTime.since(start);
    const elapsed_ms = elapsed / 1_000_000; // Convert to milliseconds
    std.debug.print("{s} elapsed => {d}ms\n", .{ name, elapsed_ms });
}

pub fn processSequence(seq: *const Sequence, allocator: std.mem.Allocator) !c.Sound {
    // Generate the WAV sequence
    const totalSamples = calcTotalSamples(seq.Bpm, LOOP_DURATION);
    const writeBuffer = try allocator.alloc(i16, totalSamples);
    //defer allocator.free(writeBuffer);

    //const s = try startTime();
    const mixedWave = generateSequence(
        seq,
        LOOP_DURATION,
        seq.Bpm,
        writeBuffer,
        totalSamples,
    );
    const soundWave = c.LoadSoundFromWave(mixedWave);
    //try endTimePrint("generateSequence => TODO", s);
    //defer c.UnloadSound(soundWave);

    // Write the wav to the filesystem asap.
    var buf: [64]u8 = undefined;
    const filename = try std.fmt.bufPrintZ(&buf, "{s} - {s}.wav", .{ seq.Song, seq.Artist });
    if (!c.ExportWave(mixedWave, filename)) {
        std.debug.print("Failed to dump .wav file!\n", .{});
    }

    return soundWave;
}

pub fn genWav(allocator: std.mem.Allocator) !void {
    c.InitAudioDevice(); // Needed for `LoadWave()`

    loadSamples();
    defer unloadSamples();

    // Test Sound: Sounds accurate to me so far:
    // Pattern{ .timing = "xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx", .name = "tick", .volume = 0.5, .sample = &hihat_closed },
    // Pattern{ .timing = "x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___", .name = "bass drum", .volume = 0.5, .sample = &kick },
    // Pattern{ .timing = "____|x___|____|x___|____|x___|____|x___|____|x___|____|x___|____|x___|____|x___", .name = "clap", .volume = 0.5, .sample = &clap },

    const Item = struct {
        seq: *const Sequence,
        sound: c.Sound,

        const Self = @This();

        fn dump(self: Self) void {
            std.debug.print("{s} - {s} @ {d}bpm\n", .{ self.seq.Song, self.seq.Artist, self.seq.Bpm });
        }
    };

    const s = try startTime();
    var seqIdx: usize = 0;
    const seqList = [_]Item{
        .{ .seq = &seqCL, .sound = try processSequence(&seqCL, allocator) },
        .{ .seq = &seqFITM, .sound = try processSequence(&seqFITM, allocator) },
        .{ .seq = &seqJOI, .sound = try processSequence(&seqJOI, allocator) },
        .{ .seq = &seqEE, .sound = try processSequence(&seqEE, allocator) },
        .{ .seq = &seqPR, .sound = try processSequence(&seqPR, allocator) },
        .{ .seq = &seq19, .sound = try processSequence(&seq19, allocator) },
        .{ .seq = &seqHOT, .sound = try processSequence(&seqHOT, allocator) },
        .{ .seq = &seqBU, .sound = try processSequence(&seqBU, allocator) },
    };
    try endTimePrint("Processed all loops in:", s);

    std.debug.print("\n\n\n\n", .{});

    // Hacky stuff
    //c.SetSoundPitch(soundWave, 1.0);

    // NOTE: Audio plays async, while loop is all good.
    // Notice this is const and not a variable? Yeah, fuck you too.
    const beatsRemainFresh = true;
    const BAR_COUNT = 4; // play for at least two bars
    var lastSound: ?c.Sound = null;
    var currSound = seqList[seqIdx].sound;

    // Start initial song.
    c.PlaySound(currSound);
    var barCount: usize = 1;
    seqList[seqIdx].dump();
    while (beatsRemainFresh) {
        if (!c.IsSoundPlaying(currSound)) {
            if (barCount < BAR_COUNT) {
                // play again
                barCount += 1;
                c.PlaySound(currSound);
            } else {
                // switch songs
                barCount = 1; // Reset for new sound
                seqIdx += 1;
                if (seqIdx >= seqList.len) {
                    seqIdx = 0;
                }

                // Swap sounds
                lastSound = currSound;
                currSound = seqList[seqIdx].sound;
                seqList[seqIdx].dump();
                c.PlaySound(currSound);
            }
        }
        // Chill the fuck out, CPU.
        std.Thread.sleep(std.time.ns_per_ms * 1);
    }

    // This sleeps the main thread...but it's ok because audio is played in a different thread.
    //std.Thread.sleep(std.time.ns_per_s * (LOOP_DURATION + 1));
    //std.debug.print("Sound finished playing.\n", .{});
}

fn mixWave(buffer: []i16, wave: ?*c.Wave, start_sample: usize, volume: f32) void {
    if (wave == null) {
        return;
    }

    var sampleIndex: usize = 0;
    const waveData: [*]i16 = @alignCast(@ptrCast(wave.?.data));
    const waveSize = wave.?.frameCount;

    while (sampleIndex < waveSize and (start_sample + sampleIndex) < buffer.len) : (sampleIndex += 1) {
        buffer[start_sample + sampleIndex] +|= @intFromFloat(@as(f32, @floatFromInt(waveData[sampleIndex])) * volume);
    }
}

// Verify if working or not.
fn applyFadeOut(buffer: []i16, fade_duration_ms: usize) void {
    const fade_samples = (SAMPLE_RATE * fade_duration_ms) / 1000;
    const total_samples = buffer.len;

    if (fade_samples >= total_samples) {
        return; // Avoid fade-out if the duration is too long
    }

    for (0..fade_samples) |i| {
        const fade_factor = @as(f32, @floatFromInt(fade_samples - i)) / @as(f32, @floatFromInt(fade_samples));
        buffer[total_samples - fade_samples + i] = @intFromFloat(@as(f32, @floatFromInt(buffer[total_samples - fade_samples + i])) * fade_factor);
    }
}

// Verify if working or not.
fn trimWaveEnd(buffer: []i16, total_samples: usize, silence_threshold: i16) void {
    var last_non_silent_index: usize = total_samples;

    for (0..total_samples) |i| {
        if (@abs(buffer[i]) > silence_threshold) {
            last_non_silent_index = i;
        }
    }

    // Clear remaining samples
    for (last_non_silent_index + 1..total_samples) |i| {
        buffer[i] = 0;
    }
}

fn calcTotalSamples(bpm: u32, duration: comptime_int) usize {
    // WARNING: This is duplicate code from generateSequence func...but I need the other vars.
    const beats_per_second = @as(f32, @floatFromInt(bpm)) / 60.0;
    const total_beats = beats_per_second * @as(f32, @floatFromInt(duration));
    const beat_samples: f32 = (SAMPLE_RATE * 60) / @as(f32, @floatFromInt(bpm));
    const totalSamples = @as(usize, @intFromFloat(total_beats * beat_samples));
    return totalSamples;
}

fn generateSequence(
    seq: *const Sequence,
    duration: u32,
    bpm: u32,
    writeBuffer: []i16,
    writeBufferSize: usize,
) c.Wave {
    // WARNING: This is duplicate code from calcTotalSamples func...but I need the other vars.
    const beats_per_second = @as(f32, @floatFromInt(bpm)) / 60.0;
    const total_beats = beats_per_second * @as(f32, @floatFromInt(duration));
    const beat_samples: f32 = (SAMPLE_RATE * 60) / @as(f32, @floatFromInt(bpm));
    const totalSamples = @as(usize, @intFromFloat(total_beats * beat_samples));

    // Technically don't need this but was trying to pull off some comptime bullshit that
    // will need more work. The writeBuffer slice has a .len obviously baked in.
    _ = writeBufferSize;

    // Clean the memory to ensure artifacts don't show up in the final output.
    @memset(writeBuffer, 0);

    // Check for an accent track
    // When present, if enabled for a given step affects all instruments at that same step.
    var accentTrack: ?*const Track = null;
    for (seq.TrackLayers) |*t| {
        if (std.mem.eql(u8, t.name, "accent")) {
            accentTrack = t;
            break;
        }
    }

    // Step duration in samples (16th-note resolution)
    const step_samples = @as(usize, @intFromFloat(beat_samples / 4.0));

    // TODO: fix this shit!
    // WARNING: Hardcoded bullshit
    // For a 32 beat pattern, 7 visual separators show up and should not be a part of this
    // calculation. For 16 beats this number will be: 3

    // NOTE: I'm inspecting the 0th layer because all layers should be the same length anyway.
    // at least for the current design.
    const tTimingLen = seq.TrackLayers[0].timing.len - 7;
    const track_length_samples = tTimingLen * step_samples; // Exact length of one full pattern in samples

    for (seq.TrackLayers) |*t| {
        var vol = t.volume;

        var step: usize = 0;
        var timingIndex: usize = 0;

        while (timingIndex < t.timing.len) : (timingIndex += 1) {
            if (t.timing[timingIndex] == '|') {
                continue; // Ignore visual separator
            }

            if (t.timing[timingIndex] == 'x') {
                var start_sample: usize = (step % tTimingLen) * step_samples;

                // Check for accent modifier
                if (accentTrack) |at| {
                    if (at.timing[timingIndex] == 'x') {
                        vol = at.volume;
                    } else {
                        vol = t.volume;
                    }
                }

                // Loop pattern continuously across the full buffer
                while (start_sample < writeBuffer.len) : (start_sample += track_length_samples) {
                    if (start_sample + step_samples <= writeBuffer.len) {
                        mixWave(writeBuffer, t.sample, start_sample, vol);
                    }
                }
            }

            step += 1; // Only increment step for valid beats
        }
    }

    // These two lines are untested in terms of if they're actually doing anything useful or not.
    // TODO: A closer look is needed here.
    applyFadeOut(writeBuffer, 150); // Smooth fade-out over last 150ms
    trimWaveEnd(writeBuffer, totalSamples, 10); // Remove low-level noise

    return c.Wave{
        .sampleRate = SAMPLE_RATE,
        .sampleSize = BIT_DEPTH,
        .channels = CHANNELS,
        // NOTE: I'm just generating a single loop now,
        // Use totalSamples to generate the entire requested duration.
        .frameCount = @intCast(track_length_samples), //@intCast(totalSamples),
        .data = writeBuffer.ptr,
    };
}
