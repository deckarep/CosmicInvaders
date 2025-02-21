const std = @import("std");
const c = @import("cdefs.zig").c;

const SAMPLE_RATE = 44100; // Standard audio sample rate
const BUFFER_SIZE = 44100; // 1 second of audio data (44100 samples)
const CHANNELS = 1; // Mono audio
const BIT_DEPTH = 16; // 16-bit audio

const Pattern = struct {
    timing: []const u8, // "x---|x---|x---|x-x-"
    name: []const u8, // The instrument name (e.g., "kick")
    volume: f32, // Volume multiplier
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

pub fn genWav() void {
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
    rim = c.LoadWave("data/drum_samples/rim.wav");

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
    const bpm: u32 = 127; // Testing

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

        // Planet Rock 32 beats - 127 bpm - WORKS!
        Pattern{ .timing = "x---|--x-|----|----|x---|--x-|--x-|----", .name = "kick", .volume = 1.0, .sample = &kick },
        Pattern{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "snare", .volume = 1.0, .sample = &snare },
        Pattern{ .timing = "----|x---|----|x---|----|x---|----|x---", .name = "clap", .volume = 1.0, .sample = &clap },
        Pattern{ .timing = "x-x-|x-xx|-x-x|x-x-|x-x-|x-xx|-x-x|x-x-", .name = "cowbell", .volume = 0.75, .sample = &cowbell },
        Pattern{ .timing = "x-xx|x-xx|x-xx|xxxx|x-xx|x-xx|x-xx|xxxx", .name = "closed_hat", .volume = 0.75, .sample = &hihat_closed },
    };

    // Generate the WAV sequence
    const mixedWave = generateSequence(&patterns, 30, bpm); // 30-second drum loop
    if (!c.ExportWave(mixedWave, "drum_sequence.wav")) {
        std.debug.print("Failed to dump .wav file!\n", .{});
    }
}

fn mixWave(buffer: []i16, wave: *c.Wave, start_sample: usize, volume: f32) void {
    var sampleIndex: usize = 0;
    const waveData: [*]i16 = @alignCast(@ptrCast(wave.data));
    const waveSize = wave.frameCount;

    while (sampleIndex < waveSize and (start_sample + sampleIndex) < buffer.len) : (sampleIndex += 1) {
        buffer[start_sample + sampleIndex] +|= @intFromFloat(@as(f32, @floatFromInt(waveData[sampleIndex])) * volume);
    }
}

fn generateSequence(patterns: []const Pattern, comptime duration: u32, comptime bpm: u32) c.Wave {
    const beats_per_second = @as(f32, @floatFromInt(bpm)) / 60.0;
    const total_beats = beats_per_second * @as(f32, @floatFromInt(duration));
    const beat_samples = (SAMPLE_RATE * 60) / bpm;
    const total_samples = @as(usize, @intFromFloat(total_beats * @as(f32, beat_samples)));
    //const total_samples = SAMPLE_RATE * duration;
    var buffer: [total_samples]i16 = [_]i16{0} ** total_samples;

    // Calculate beats per minute timing
    const step_samples = @as(usize, @intFromFloat(@as(f32, @floatFromInt(beat_samples)) / 4.0)); // Assuming 16th-note resolution

    for (patterns) |*p| {
        var step: usize = 0;
        var timingIndex: usize = 0;

        while (timingIndex < p.timing.len) : (timingIndex += 1) {
            if (p.timing[timingIndex] == '|') {
                continue; // Ignore visual separator
            }
            if (p.timing[timingIndex] == 'x') {
                const start_sample = step * step_samples;
                if (start_sample < buffer.len) {
                    mixWave(&buffer, p.sample, start_sample, p.volume);
                }
            }
            step += 1; // Only increment step for valid beats
        }
    }

    return c.Wave{
        .sampleRate = SAMPLE_RATE,
        .sampleSize = BIT_DEPTH,
        .channels = CHANNELS,
        .frameCount = total_samples,
        .data = &buffer,
    };
}
