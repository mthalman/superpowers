---
name: web-audio-designer
description: Use when creating audio from written descriptions - generates high-quality sound effects, musical tones, UI feedback sounds, ambient soundscapes, and game audio using Web Audio API for JavaScript. Triggered by requests like "create a button click sound", "generate a sci-fi whoosh", or "make an 8-bit power-up jingle".
---

# Web Audio Designer

## Overview

This skill enables the creation of high-quality procedural audio based on written descriptions. Generate sound effects, musical sequences, UI feedback sounds, ambient soundscapes, and game audio using the Web Audio API for JavaScript. All audio is created programmatically - no audio files required.

## When to Use This Skill

Use this skill when the user requests audio creation or sound generation from a text description:

- **UI/UX sounds**: Button clicks, notifications, success chimes, error buzzes, hover effects
- **Game audio**: Explosions, lasers, jumps, power-ups, 8-bit sounds, retro effects
- **Musical elements**: Tones, chords, arpeggios, melodies, sequences
- **Transitions**: Whooshes, swooshes, fades, sweeps
- **Ambient sounds**: Rain, ocean waves, wind, background atmospheres
- **Sci-fi/futuristic**: Door sounds, beeps, computer interfaces, space ambiences

**Example triggers:**
- "Create a satisfying button click sound"
- "Generate an 8-bit style power-up jingle"
- "Make a sci-fi door whoosh sound"
- "Build a relaxing ocean waves ambient sound"
- "Create an error buzz for failed actions"

## Core Workflow

### 1. Understand the Audio Requirements

Analyze the user's description to identify:

- **Type of sound**: UI feedback, game effect, musical, ambient, transition
- **Emotional quality**: Satisfying, energetic, calming, attention-grabbing, negative
- **Characteristics**: Duration, pitch range, timbre, rhythm
- **Context**: Where/how will the sound be used?

### 2. Select the Appropriate Pattern

Refer to `references/sound-design-patterns.md` for common audio patterns:

- **UI sounds**: Clicks, chimes, notifications, errors
- **Game effects**: Explosions, lasers, jumps, power-ups, 8-bit sounds
- **Transitions**: Whooshes, sweeps, door sounds
- **Ambient**: Rain, ocean waves, continuous atmospheres

Each pattern includes complete code examples with explanations of key characteristics.

### 3. Apply Web Audio API Techniques

Use `references/web-audio-reference.md` for technical implementation:

- **Audio nodes**: Oscillators, gain, filters, noise generation, delay, panning
- **Waveforms**: Sine (pure), square (retro), sawtooth (bright), triangle (mellow)
- **Envelopes**: ADSR (Attack-Decay-Sustain-Release) for shaping sounds
- **Filters**: Lowpass (warm), highpass (bright), bandpass (focused)
- **Automation**: Pitch sweeps, volume fades, filter movements
- **Musical notes**: Frequency tables and MIDI conversion

### 4. Generate Complete, Runnable Code

Create a complete HTML file that:

- Initializes the AudioContext (must be triggered by user interaction)
- Implements the audio generation function
- Includes a button to play the sound
- Contains clear comments explaining the audio design choices

**Template structure:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>[Sound Name]</title>
</head>
<body>
    <button id="playBtn">Play [Sound Name]</button>

    <script>
        let audioContext;

        document.getElementById('playBtn').addEventListener('click', () => {
            if (!audioContext) {
                audioContext = new (window.AudioContext || window.webkitAudioContext)();
            }

            // Audio generation code here
        });
    </script>
</body>
</html>
```

### 5. Explain the Design Choices

After generating the code, briefly explain:

- **Why specific waveforms were chosen** (e.g., "square wave for retro 8-bit character")
- **How the envelope shapes the sound** (e.g., "quick attack for percussive feel")
- **Filter choices and frequency ranges** (e.g., "lowpass at 800Hz for warmth")
- **Timing and duration decisions** (e.g., "50ms for responsive UI feedback")

## Key Principles

### Sound Design Quality

- **Avoid clicks/pops**: Always use short fade-ins/fade-outs (1-10ms) when starting/stopping oscillators
- **Appropriate duration**: UI sounds 20-150ms, feedback 150-400ms, transitions 300-1000ms
- **Volume levels**: Keep between 0.1-0.4 to prevent clipping, layer sounds at lower volumes
- **Emotional alignment**: Match sound characteristics to the desired feeling
  - Satisfying: Mid-frequency, two-tone, quick decay
  - Pleasant: Major intervals, soft waveforms, smooth envelopes
  - Energetic: Bright tones, ascending pitches, quick movements
  - Calming: Low frequencies, soft attacks, gentle filtering
  - Negative: Lower pitches, dissonance, descending movement

### Technical Quality

- **Precise timing**: Use `audioContext.currentTime` for scheduling, not `setTimeout`
- **Clean code**: Organize audio functions for reusability
- **Browser compatibility**: Include webkit prefix support
- **User interaction**: AudioContext must be created after user gesture

### Layering for Richness

Combine multiple elements for professional results:
- Oscillators for tonal content
- Noise for texture and realism
- Filters for character and movement
- Multiple frequency bands for depth

## Common Patterns Quick Reference

**Button click**: Sine wave, 800→400 Hz sweep, 50ms duration, sharp attack
**Success chime**: Major chord arpeggio, triangle wave, ascending, 300ms
**Error buzz**: Square wave, 220→110 Hz descending, 150ms, harsh
**Laser**: Sawtooth, 1200→100 Hz fast sweep, bandpass filter, 150ms
**Whoosh**: Filtered noise, sweeping bandpass 200→4000 Hz, stereo pan, 600ms
**Explosion**: White noise + low sine thump, sweeping lowpass, 1.5s decay
**8-bit power-up**: Square wave, rapid arpeggio, bright frequencies
**Ocean waves**: Looping filtered noise, slow LFO modulation, continuous

## Resources

### references/web-audio-reference.md
Comprehensive technical reference for the Web Audio API, including:
- All audio node types with examples
- Waveform characteristics and use cases
- Audio parameter automation methods
- ADSR envelope implementation
- Musical note frequency tables
- Timing and scheduling best practices
- Complete HTML template

Load this file when technical details are needed about Web Audio API implementation.

### references/sound-design-patterns.md
Common audio patterns with complete code examples, including:
- UI sound effects (clicks, chimes, notifications, errors)
- Game sound effects (explosions, lasers, jumps, 8-bit sounds)
- Transition effects (whooshes, swooshes, sci-fi doors)
- Ambient sounds (rain, ocean waves, continuous atmospheres)
- Design tips for quality and feel

Load this file to find patterns matching the requested sound type and see complete implementations.

## Usage Notes

- **Always read the relevant reference files** before implementing - they contain proven patterns and important technical details
- **Start with similar patterns** from sound-design-patterns.md and adapt to requirements
- **Combine and layer** elements from multiple patterns for unique sounds
- **Test the generated audio** by opening the HTML file in a browser
- **Iterate based on feedback** - audio design is subjective, refine based on user response
- **Keep code clean and commented** - explain the audio design thinking in comments
