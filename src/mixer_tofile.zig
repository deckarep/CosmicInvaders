const std = @import("std");
const c = @import("cdefs.zig").c;

// Reference tracks: https://robricketts.bigcartel.com/product/pretty-tony-fix-it-in-the-mix

// Question: How much of this can be done at comptime?
// Can we take a text pattern => in-memory mixed waveform all at comptime?
// We could if our samples were not loaded as files but embeded binary data.

const SAMPLE_RATE = 44100; // Standard audio sample rate
const BUFFER_SIZE = 44100; // 1 second of audio data (44100 samples)
const CHANNELS = 1; // Mono audio
const BIT_DEPTH = 16; // 16-bit audio

const Pattern = struct {
    timing: []const u8, // "x---|x---|x---|x-x-"
    name: []const u8, // The instrument name (e.g., "kick")
    volume: f32 = 1.0, // Volume multiplier, 1.0 is default when unspecified.
    sample: *c.Wave, // Loaded WAV file
};

var kick: c.Wave = undefined;
var snare: c.Wave = undefined;
var hihat_open: c.Wave = undefined;
var hihat_closed: c.Wave = undefined;
var clap: c.Wave = undefined;
var cowbell: c.Wave = undefined;
var tomhi: c.Wave = undefined;
var tomlow: c.Wave = undefined;
var rim: c.Wave = undefined;

pub fn genWav(allocator: std.mem.Allocator) !void {
    c.InitAudioDevice(); // Needed for `LoadWave()`

    // Load drum samples
    kick = c.LoadWave("data/drum_samples/bass-drum.wav");
    snare = c.LoadWave("data/drum_samples/snare.wav");
    hihat_closed = c.LoadWave("data/drum_samples/hihat-closed.wav");
    hihat_open = c.LoadWave("data/drum_samples/hihat-open.wav");
    clap = c.LoadWave("data/drum_samples/clap.wav");
    cowbell = c.LoadWave("data/drum_samples/cowbell.wav");
    tomhi = c.LoadWave("data/drum_samples/tom-hi.wav");
    tomlow = c.LoadWave("data/drum_samples/tom-low.wav");
    rim = c.LoadWave("data/drum_samples/rim-shot.wav");

    // Clean up memory
    defer c.UnloadWave(kick);
    defer c.UnloadWave(snare);
    defer c.UnloadWave(hihat_open);
    defer c.UnloadWave(hihat_closed);
    defer c.UnloadWave(clap);
    defer c.UnloadWave(cowbell);
    defer c.UnloadWave(tomhi);
    defer c.UnloadWave(tomlow);
    defer c.UnloadWave(rim);

    //const bpm: u32 = 138; //Madonna Burning Up
    //const bpm: u32 = 118; // Thriller
    const bpm: u32 = 118; // Testing

    // Define the beat pattern
    const patterns = [_]Pattern{
        // Thriller - 118 bpm
        // Pattern{ .timing = "x-x-|x-xx|x-x-|x-x-", .name = "hi-hat", .volume = 1.0, .sample = &hihat_closed },
        // Pattern{ .timing = "----|----|---x|---x", .name = "hi-hat-long", .volume = 1.0, .sample = &hihat_open },
        // Pattern{ .timing = "---x|--x-|----|----", .name = "conga-high", .volume = 1.0, .sample = &tomhi },
        // Pattern{ .timing = "----|x---|x--x|--x-", .name = "conga-low", .volume = 1.0, .sample = &tomlow },
        // Pattern{ .timing = "---x|---x|----|----", .name = "cowbell", .volume = 1.0, .sample = &cowbell },
        // Pattern{ .timing = "----|----|----|x---", .name = "clap", .volume = 1.0, .sample = &clap },
        // Pattern{ .timing = "----|x---|----|x---", .name = "snare", .volume = 1.0, .sample = &snare },
        // Pattern{ .timing = "x---|x---|x---|x---", .name = "kick", .volume = 1.0, .sample = &kick },
        // Pattern{ .timing = "x-x-|x-x-|x-x-|x-x-|x-x-|x-x-|x-x-|x-x-", .name = "hi-hat-short", .volume = 1.0, .sample = &hihat_closed },
        // Pattern{ .timing = "----|----|----|---x|----|----|----|---x", .name = "hi-hat", .volume = 1.0, .sample = &hihat_open },
        // Pattern{ .timing = "----|x-x-|----|x---|----|x-x-|----|x---", .name = "clap", .volume = 1.0, .sample = &clap },
        // Pattern{ .timing = "----|x-x-|----|x---|----|x-x-|----|x---", .name = "snare-low", .volume = 1.0, .sample = &snare },
        // Pattern{ .timing = "x---|x---|x---|x-x-|x---|x---|x---|x-x-", .name = "kick", .volume = 1.0, .sample = &kick },

        // Burning up - Madonna
        // Pattern{ .timing = "x-x-|x-x-|x-x-|x-x-", .name = "hi-hat-short", .volume = 1.0, .sample = &hihat_closed },
        // Pattern{ .timing = "----|----|----|---x", .name = "hi-hat", .volume = 1.0, .sample = &hihat_open },
        // Pattern{ .timing = "----|x-x-|----|x---", .name = "clap", .volume = 1.0, .sample = &clap },
        // Pattern{ .timing = "----|x-x-|----|x---", .name = "snare-low", .volume = 1.0, .sample = &snare },
        // Pattern{ .timing = "x---|x---|x---|x-x-", .name = "kick", .volume = 1.0, .sample = &kick },

        // Test Sound: Sounds accurate to me so far:
        // Pattern{ .timing = "xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx", .name = "tick", .volume = 0.5, .sample = &hihat_closed },
        // Pattern{ .timing = "x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___|x___", .name = "bass drum", .volume = 0.5, .sample = &kick },
        // Pattern{ .timing = "____|x___|____|x___|____|x___|____|x___|____|x___|____|x___|____|x___|____|x___", .name = "clap", .volume = 0.5, .sample = &clap },

        // 19 - Paul Hardcastle - 32 beats - 118bpm
        Pattern{ .timing = "xx-x|---x|--x-|x---|xx-x|---x|--x-|x---", .name = "bd", .sample = &kick },
        Pattern{ .timing = "----|x---|----|x---|----|x---|----|x-xx", .name = "sd", .sample = &snare },
        Pattern{ .timing = "x--x|--x-|--xx|x---|x--x|--x-|--x-|-x--", .name = "rs", .sample = &rim },
        Pattern{ .timing = "----|x---|----|x---|----|x---|----|x-xx", .name = "cp", .sample = &clap },
        Pattern{ .timing = "xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx", .name = "ch", .sample = &hihat_closed },

        // ✅ Hangin' on a String - Loose Ends - 32 beats - 105bpm
        // Pattern{ .timing = "x---|--x-|x---|----|x---|--x-|x---|----", .name = "bd", .sample = &kick },
        // Pattern{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "sd", .sample = &snare },
        // Pattern{ .timing = "---x|----|----|x---|----|----|----|----", .name = "rs", .sample = &rim },
        // Pattern{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "cp", .sample = &clap },
        // Pattern{ .timing = "----|----|--xx|xxx-|----|----|----|----", .name = "cb", .volume = 0.25, .sample = &cowbell },
        // Pattern{ .timing = "x---|----|----|----|----|----|x---|----", .name = "oh", .sample = &hihat_open },
        // Pattern{ .timing = "---x|x-x-|x--x|x-x-|x--x|x-x-|-x-x|xxx-", .name = "ch", .sample = &hihat_closed },

        // ✅ Fix in the Mix - Prety Tony 32 beats - 129bpm
        // Pattern{ .timing = "x---|--x-|--x-|-x--|x---|--x-|----|----", .name = "kick", .sample = &kick },
        // Pattern{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "snare", .sample = &snare },
        // Pattern{ .timing = "x-xx|x-xx|x-xx|xxxx|x-xx|x-xx|x-xx|xxxx", .name = "ch", .sample = &hihat_closed },

        // ✅ Egypt Egypt 32 beats - 127 - Close, missing accent programming. How to do?
        // Pattern{ .timing = "x---|--x-|--x-|-x--|x---|--x-|--x-|--x-", .name = "kick", .sample = &kick },
        // Pattern{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "snare", .sample = &snare },
        // Pattern{ .timing = "x-x-|xxx-|x-xx|-xx-|x-x-|xxx-|x-xx|-xx-", .name = "cowbell", .volume = 1.0, .sample = &cowbell },
        // Pattern{ .timing = "xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx", .name = "closed_hat", .volume = 0.75, .sample = &hihat_closed },

        // ✅ Part 2 (Egypt Egypt) ChatGPT AI beat attempt
        // Pattern{ .timing = "x---|--x-|x--x|-x--|x---|--x-|--x-|--x-", .name = "kick", .sample = &kick },
        // Pattern{ .timing = "----|x---|----|x---|----|x-x-|----|x---", .name = "snare", .sample = &snare },
        // Pattern{ .timing = "x-x-|xxx-|x-xx|-xx-|x-x-|x-xx|x-x-|-xx-", .name = "cowbell", .volume = 1.0, .sample = &cowbell },
        // Pattern{ .timing = "xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|----", .name = "closed_hat", .volume = 0.75, .sample = &hihat_closed },

        // ✅ Jam on It 32 Beats - 116 bpm - PERFECT!
        // Pattern{ .timing = "x---|---x|-xx-|--x-|xx--|---x|-xx-|x-x-", .name = "kick", .sample = &kick },
        // Pattern{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "snare", .sample = &snare },
        // Pattern{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "clap", .sample = &clap },
        // Pattern{ .timing = "xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx", .name = "closed_hat", .volume = 0.75, .sample = &hihat_closed },

        // ✅ Planet Rock 32 beats - 127 bpm - PERFECT!
        // Pattern{ .timing = "x---|--x-|----|----|x---|--x-|--x-|----", .name = "kick", .volume = 1.0, .sample = &kick },
        // Pattern{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "snare", .volume = 1.0, .sample = &snare },
        // Pattern{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "clap", .volume = 1.0, .sample = &clap },
        // Pattern{ .timing = "x-x-|x-xx|-x-x|x-x-|x-x-|x-xx|-x-x|x-x-", .name = "cowbell", .volume = 0.75, .sample = &cowbell },
        // Pattern{ .timing = "x-xx|x-xx|x-xx|xxxx|x-xx|x-xx|x-xx|xxxx", .name = "closed_hat", .volume = 0.75, .sample = &hihat_closed },
    };

    // Generate the WAV sequence
    const mixedWave = try generateSequence(&patterns, 30, bpm, allocator); // 30-second drum loop

    const soundWave = c.LoadSoundFromWave(mixedWave);

    // Write the wav to the filesystem asap.
    // TODO: free, but mixedWave.data is an ?*anyopaque
    //defer allocator.free(mixedWave.data);
    if (!c.ExportWave(mixedWave, "drum_sequence.wav")) {
        std.debug.print("Failed to dump .wav file!\n", .{});
    }

    defer c.UnloadSound(soundWave);
    c.PlaySound(soundWave);

    // This sleeps the main thread...but it's ok because audio is played in a different thread.
    std.Thread.sleep(std.time.ns_per_s * 31);
    std.debug.print("Sound finished playing.\n", .{});
}

fn mixWave(buffer: []i16, wave: *c.Wave, start_sample: usize, volume: f32) void {
    var sampleIndex: usize = 0;
    const waveData: [*]i16 = @alignCast(@ptrCast(wave.data));
    const waveSize = wave.frameCount;

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

fn generateSequence(
    patterns: []const Pattern,
    comptime duration: u32,
    comptime bpm: u32,
    allocator: std.mem.Allocator,
) !c.Wave {
    const beats_per_second = @as(f32, @floatFromInt(bpm)) / 60.0;
    const total_beats = beats_per_second * @as(f32, @floatFromInt(duration));
    const beat_samples = (SAMPLE_RATE * 60) / bpm;
    const total_samples = @as(usize, @intFromFloat(total_beats * @as(f32, beat_samples)));

    //var buffer: [total_samples]i16 = [_]i16{0} ** total_samples;
    const buffer = try allocator.alloc(i16, total_samples);
    @memset(buffer, 0);

    // Step duration in samples (16th-note resolution)
    const step_samples = @as(usize, @intFromFloat(@as(f32, @floatFromInt(beat_samples)) / 4.0));

    for (patterns) |*p| {
        // TODO: fix this shit!
        // WARNING: Hardcoded bullshit
        // For a 32 beat pattern, 7 visual separators show up and should not be a part of this
        // calculation. For 16 beats this number will be: 3
        const pTimingLen = p.timing.len - 7;

        const pattern_length_samples = pTimingLen * step_samples; // Exact length of one full pattern in samples
        var step: usize = 0;
        var timingIndex: usize = 0;

        while (timingIndex < p.timing.len) : (timingIndex += 1) {
            if (p.timing[timingIndex] == '|') {
                continue; // Ignore visual separator
            }

            if (p.timing[timingIndex] == 'x') {
                var start_sample: usize = (step % pTimingLen) * step_samples; //step * step_samples;
                // std.debug.print("name => {s}, step => {d}, p.timing.len => {d}, step_samples => {d}, start_sample => {d}\n", .{
                //     p.name,
                //     step + 1,
                //     p.timing.len,
                //     step_samples,
                //     start_sample,
                // });

                // Loop pattern continuously across the full buffer
                while (start_sample < buffer.len) : (start_sample += pattern_length_samples) {
                    if (start_sample + step_samples <= buffer.len) {
                        mixWave(buffer, p.sample, start_sample, p.volume);
                    }
                }
            }
            step += 1; // Only increment step for valid beats
        }
    }

    // These two lines are not working yet...
    // Still hearing artifcats at the end of the sound effect.
    applyFadeOut(buffer, 150); // Smooth fade-out over last 150ms
    trimWaveEnd(buffer, total_samples, 10); // Remove low-level noise

    return c.Wave{
        .sampleRate = SAMPLE_RATE,
        .sampleSize = BIT_DEPTH,
        .channels = CHANNELS,
        .frameCount = total_samples,
        .data = buffer.ptr,
    };
}
