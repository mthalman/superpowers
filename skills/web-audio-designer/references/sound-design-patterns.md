# Sound Design Patterns

This document contains common patterns and techniques for creating different types of audio using Web Audio API.

## UI Sound Effects

### Button Click

Short, percussive sound with quick attack and decay.

**Key characteristics:**
- Very short duration (20-100ms)
- Sharp attack (1-5ms)
- Minimal sustain
- Quick release
- Mid-to-high frequency (400-2000 Hz)

```javascript
function createButtonClick() {
    const osc = audioContext.createOscillator();
    const gain = audioContext.createGain();

    osc.connect(gain);
    gain.connect(audioContext.destination);

    // Two-tone click for depth
    osc.type = 'sine';
    osc.frequency.setValueAtTime(800, audioContext.currentTime);
    osc.frequency.exponentialRampToValueAtTime(400, audioContext.currentTime + 0.02);

    // Sharp attack, quick decay
    gain.gain.setValueAtTime(0.3, audioContext.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.05);

    osc.start(audioContext.currentTime);
    osc.stop(audioContext.currentTime + 0.05);
}
```

### Success Chime

Bright, ascending musical sound that feels positive.

**Key characteristics:**
- Multiple notes (chord or arpeggio)
- Ascending pitch
- Clean, pleasant waveforms (sine, triangle)
- Medium duration (200-500ms)
- Major intervals for positive feeling

```javascript
function createSuccessChime() {
    const now = audioContext.currentTime;

    // Play major chord notes in sequence (C-E-G-C)
    const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
    const noteInterval = 0.08;

    notes.forEach((freq, i) => {
        const osc = audioContext.createOscillator();
        const gain = audioContext.createGain();

        osc.connect(gain);
        gain.connect(audioContext.destination);

        osc.type = 'triangle';
        osc.frequency.value = freq;

        const startTime = now + (i * noteInterval);
        gain.gain.setValueAtTime(0.2, startTime);
        gain.gain.exponentialRampToValueAtTime(0.01, startTime + 0.4);

        osc.start(startTime);
        osc.stop(startTime + 0.4);
    });
}
```

### Error Buzz

Low, harsh sound that signals something went wrong.

**Key characteristics:**
- Low frequency (100-300 Hz)
- Dissonant or harsh (square wave, low-tuned intervals)
- Short duration
- Can include brief descending pitch

```javascript
function createErrorBuzz() {
    const osc = audioContext.createOscillator();
    const gain = audioContext.createGain();
    const filter = audioContext.createBiquadFilter();

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(audioContext.destination);

    // Harsh square wave
    osc.type = 'square';
    osc.frequency.setValueAtTime(220, audioContext.currentTime);
    osc.frequency.exponentialRampToValueAtTime(110, audioContext.currentTime + 0.15);

    // Filter to reduce harshness slightly
    filter.type = 'lowpass';
    filter.frequency.value = 800;

    gain.gain.setValueAtTime(0.2, audioContext.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.15);

    osc.start(audioContext.currentTime);
    osc.stop(audioContext.currentTime + 0.15);
}
```

### Notification Beep

Clear, attention-grabbing sound that's not too jarring.

**Key characteristics:**
- Pure sine wave for clarity
- Mid-high frequency (600-1200 Hz)
- Can be two-tone for interest
- Short but noticeable (100-200ms)

```javascript
function createNotification() {
    const now = audioContext.currentTime;

    // Two quick beeps
    [0, 0.15].forEach(delay => {
        const osc = audioContext.createOscillator();
        const gain = audioContext.createGain();

        osc.connect(gain);
        gain.connect(audioContext.destination);

        osc.type = 'sine';
        osc.frequency.value = 880; // A5

        const startTime = now + delay;
        gain.gain.setValueAtTime(0.15, startTime);
        gain.gain.exponentialRampToValueAtTime(0.01, startTime + 0.1);

        osc.start(startTime);
        osc.stop(startTime + 0.1);
    });
}
```

## Game Sound Effects

### 8-Bit Power-Up

Classic retro video game sound with ascending arpeggio.

**Key characteristics:**
- Square or triangle waves (chiptune sound)
- Rapid ascending notes
- Bright, energetic
- Short note durations

```javascript
function create8BitPowerUp() {
    const now = audioContext.currentTime;

    // Rapid ascending arpeggio
    const notes = [261.63, 329.63, 392.00, 523.25, 659.25]; // C4-E4-G4-C5-E5
    const noteLength = 0.06;

    notes.forEach((freq, i) => {
        const osc = audioContext.createOscillator();
        const gain = audioContext.createGain();

        osc.connect(gain);
        gain.connect(audioContext.destination);

        osc.type = 'square';
        osc.frequency.value = freq;

        const startTime = now + (i * noteLength);
        gain.gain.setValueAtTime(0.15, startTime);
        gain.gain.linearRampToValueAtTime(0, startTime + noteLength * 1.5);

        osc.start(startTime);
        osc.stop(startTime + noteLength * 1.5);
    });
}
```

### Explosion

Noise-based sound with characteristic boom.

**Key characteristics:**
- White or filtered noise
- Initial low-frequency punch
- Decay over time
- Lowpass filter sweeping down

```javascript
function createExplosion() {
    const now = audioContext.currentTime;

    // Create noise buffer
    const bufferSize = audioContext.sampleRate * 1.5;
    const buffer = audioContext.createBuffer(1, bufferSize, audioContext.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
        data[i] = Math.random() * 2 - 1;
    }

    const noise = audioContext.createBufferSource();
    const filter = audioContext.createBiquadFilter();
    const gain = audioContext.createGain();

    noise.buffer = buffer;
    noise.connect(filter);
    filter.connect(gain);
    gain.connect(audioContext.destination);

    // Sweeping lowpass filter
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(3000, now);
    filter.frequency.exponentialRampToValueAtTime(50, now + 1.5);
    filter.Q.value = 1;

    // Volume envelope
    gain.gain.setValueAtTime(0.5, now);
    gain.gain.exponentialRampToValueAtTime(0.01, now + 1.5);

    // Add a low-frequency thump at the start
    const thump = audioContext.createOscillator();
    const thumpGain = audioContext.createGain();
    thump.connect(thumpGain);
    thumpGain.connect(audioContext.destination);

    thump.type = 'sine';
    thump.frequency.setValueAtTime(80, now);
    thump.frequency.exponentialRampToValueAtTime(30, now + 0.2);

    thumpGain.gain.setValueAtTime(0.6, now);
    thumpGain.gain.exponentialRampToValueAtTime(0.01, now + 0.3);

    noise.start(now);
    thump.start(now);
    thump.stop(now + 0.3);
}
```

### Laser/Zap

High-to-low pitch sweep with some modulation.

**Key characteristics:**
- Sawtooth or square wave
- Fast downward pitch sweep
- Short duration (100-300ms)
- Optional frequency modulation for interest

```javascript
function createLaser() {
    const now = audioContext.currentTime;

    const osc = audioContext.createOscillator();
    const gain = audioContext.createGain();
    const filter = audioContext.createBiquadFilter();

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(audioContext.destination);

    osc.type = 'sawtooth';

    // Fast downward sweep
    osc.frequency.setValueAtTime(1200, now);
    osc.frequency.exponentialRampToValueAtTime(100, now + 0.15);

    // Bandpass for laser-like quality
    filter.type = 'bandpass';
    filter.frequency.value = 1000;
    filter.Q.value = 5;

    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.01, now + 0.15);

    osc.start(now);
    osc.stop(now + 0.15);
}
```

### Jump Sound

Bouncy, upward pitch sweep.

**Key characteristics:**
- Quick upward pitch
- Triangle or sine wave
- Short, percussive
- Light and bouncy feeling

```javascript
function createJump() {
    const now = audioContext.currentTime;

    const osc = audioContext.createOscillator();
    const gain = audioContext.createGain();

    osc.connect(gain);
    gain.connect(audioContext.destination);

    osc.type = 'triangle';

    // Quick upward sweep
    osc.frequency.setValueAtTime(200, now);
    osc.frequency.exponentialRampToValueAtTime(600, now + 0.08);

    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.01, now + 0.2);

    osc.start(now);
    osc.stop(now + 0.2);
}
```

## Transition Effects

### Whoosh/Swoosh

Filtered noise sweep, great for UI transitions.

**Key characteristics:**
- White or pink noise
- Bandpass filter sweeping across frequency range
- Medium duration (300-800ms)
- Stereo panning for movement (optional)

```javascript
function createWhoosh() {
    const now = audioContext.currentTime;

    // Create noise
    const bufferSize = audioContext.sampleRate * 0.8;
    const buffer = audioContext.createBuffer(1, bufferSize, audioContext.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
        data[i] = Math.random() * 2 - 1;
    }

    const noise = audioContext.createBufferSource();
    const filter = audioContext.createBiquadFilter();
    const gain = audioContext.createGain();
    const panner = audioContext.createStereoPanner();

    noise.buffer = buffer;
    noise.connect(filter);
    filter.connect(gain);
    gain.connect(panner);
    panner.connect(audioContext.destination);

    // Sweeping bandpass filter
    filter.type = 'bandpass';
    filter.Q.value = 10;
    filter.frequency.setValueAtTime(200, now);
    filter.frequency.exponentialRampToValueAtTime(4000, now + 0.6);

    // Volume envelope
    gain.gain.setValueAtTime(0, now);
    gain.gain.linearRampToValueAtTime(0.3, now + 0.1);
    gain.gain.linearRampToValueAtTime(0.3, now + 0.5);
    gain.gain.linearRampToValueAtTime(0, now + 0.8);

    // Pan from left to right
    panner.pan.setValueAtTime(-1, now);
    panner.pan.linearRampToValueAtTime(1, now + 0.6);

    noise.start(now);
}
```

### Sci-Fi Door

Mechanical sound with pitch movement.

**Key characteristics:**
- Low-frequency rumble with pitch movement
- Can combine with noise
- Suggests mechanical movement
- Medium duration

```javascript
function createSciFiDoor() {
    const now = audioContext.currentTime;

    // Low rumble
    const rumble = audioContext.createOscillator();
    const rumbleGain = audioContext.createGain();

    rumble.connect(rumbleGain);
    rumbleGain.connect(audioContext.destination);

    rumble.type = 'sawtooth';
    rumble.frequency.setValueAtTime(80, now);
    rumble.frequency.linearRampToValueAtTime(120, now + 0.3);
    rumble.frequency.linearRampToValueAtTime(80, now + 0.6);

    rumbleGain.gain.setValueAtTime(0, now);
    rumbleGain.gain.linearRampToValueAtTime(0.2, now + 0.05);
    rumbleGain.gain.linearRampToValueAtTime(0.2, now + 0.55);
    rumbleGain.gain.linearRampToValueAtTime(0, now + 0.7);

    // High frequency hiss
    const bufferSize = audioContext.sampleRate * 0.7;
    const buffer = audioContext.createBuffer(1, bufferSize, audioContext.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
        data[i] = Math.random() * 2 - 1;
    }

    const noise = audioContext.createBufferSource();
    const noiseFilter = audioContext.createBiquadFilter();
    const noiseGain = audioContext.createGain();

    noise.buffer = buffer;
    noise.connect(noiseFilter);
    noiseFilter.connect(noiseGain);
    noiseGain.connect(audioContext.destination);

    noiseFilter.type = 'highpass';
    noiseFilter.frequency.value = 2000;

    noiseGain.gain.setValueAtTime(0.1, now);
    noiseGain.gain.linearRampToValueAtTime(0, now + 0.7);

    rumble.start(now);
    rumble.stop(now + 0.7);
    noise.start(now);
}
```

## Ambient Sounds

### Rain

Continuous filtered noise with variations.

**Key characteristics:**
- Continuous white/pink noise
- Lowpass or bandpass filtering
- Random variations in volume
- Long duration, loopable

```javascript
function createRain() {
    // Create long noise buffer
    const duration = 3; // 3 seconds, can loop
    const bufferSize = audioContext.sampleRate * duration;
    const buffer = audioContext.createBuffer(1, bufferSize, audioContext.sampleRate);
    const data = buffer.getChannelData(0);

    // Pink noise approximation (less harsh than white noise)
    let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        b0 = 0.99886 * b0 + white * 0.0555179;
        b1 = 0.99332 * b1 + white * 0.0750759;
        b2 = 0.96900 * b2 + white * 0.1538520;
        b3 = 0.86650 * b3 + white * 0.3104856;
        b4 = 0.55000 * b4 + white * 0.5329522;
        b5 = -0.7616 * b5 - white * 0.0168980;
        data[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11;
        b6 = white * 0.115926;
    }

    const noise = audioContext.createBufferSource();
    const filter = audioContext.createBiquadFilter();
    const gain = audioContext.createGain();

    noise.buffer = buffer;
    noise.loop = true; // Loop for continuous rain
    noise.connect(filter);
    filter.connect(gain);
    gain.connect(audioContext.destination);

    // Filter to shape rain sound
    filter.type = 'bandpass';
    filter.frequency.value = 1000;
    filter.Q.value = 0.5;

    gain.gain.value = 0.2;

    noise.start();

    // Return stop function
    return () => noise.stop();
}
```

### Ocean Waves

Low-frequency oscillation with noise.

**Key characteristics:**
- Low-frequency sine wave (wave motion)
- Combined with filtered noise (water sound)
- Slow, rhythmic pattern
- Calming, continuous

```javascript
function createOceanWaves() {
    const now = audioContext.currentTime;

    // Create noise for water texture
    const bufferSize = audioContext.sampleRate * 4;
    const buffer = audioContext.createBuffer(1, bufferSize, audioContext.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
        data[i] = Math.random() * 2 - 1;
    }

    const noise = audioContext.createBufferSource();
    const filter = audioContext.createBiquadFilter();
    const noiseGain = audioContext.createGain();

    noise.buffer = buffer;
    noise.loop = true;
    noise.connect(filter);
    filter.connect(noiseGain);
    noiseGain.connect(audioContext.destination);

    filter.type = 'lowpass';
    filter.frequency.value = 800;
    filter.Q.value = 1;

    // Slow LFO for wave motion
    const lfo = audioContext.createOscillator();
    const lfoGain = audioContext.createGain();

    lfo.frequency.value = 0.2; // 0.2 Hz = one wave every 5 seconds
    lfoGain.gain.value = 0.1;

    lfo.connect(lfoGain);
    lfoGain.connect(noiseGain.gain);

    noiseGain.gain.value = 0.15;

    noise.start(now);
    lfo.start(now);

    // Return stop function
    return () => {
        noise.stop();
        lfo.stop();
    };
}
```

## Design Tips

### Avoiding Clicks and Pops
Always use short fade-ins and fade-outs (1-10ms) to avoid audible clicks when starting/stopping oscillators.

```javascript
// Bad: abrupt start
gain.gain.value = 0.5;

// Good: quick fade in
gain.gain.setValueAtTime(0, now);
gain.gain.linearRampToValueAtTime(0.5, now + 0.005);
```

### Layering Sounds
Combine multiple elements for richer sounds:
- Oscillator for tonal content
- Noise for texture
- Filters for character
- Multiple frequency bands for depth

### Timing and Feel
- UI sounds: 20-150ms (responsive feel)
- Feedback sounds: 150-400ms (noticeable but not intrusive)
- Transitions: 300-1000ms (smooth, elegant)
- Ambient: Continuous or long-looping

### Volume Levels
- Keep individual sounds between 0.1-0.4 to prevent clipping
- Layer sounds at lower volumes (0.1-0.2 each)
- Use dynamics (quiet to loud) for impact
- Test on different speakers/headphones

### Making Sounds Feel "Good"
- **Satisfying clicks**: Short, two-tone, mid-frequency
- **Pleasant chimes**: Major intervals, soft waveforms
- **Attention-grabbing**: Higher frequencies, repetition
- **Calming**: Lower frequencies, soft attacks, gentle filtering
- **Energetic**: Bright tones, quick movements, ascending pitches
- **Negative feedback**: Lower pitches, dissonance, descending movement
