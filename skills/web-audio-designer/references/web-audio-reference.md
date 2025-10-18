# Web Audio API Reference

## Core Concepts

The Web Audio API provides a powerful system for controlling audio in web applications. Audio processing is performed using audio nodes that are connected together to form an **audio routing graph**.

### Basic Setup

```javascript
// Create audio context
const audioContext = new (window.AudioContext || window.webkitAudioContext)();

// All audio must eventually connect to the destination (speakers)
audioContext.destination
```

### Key Audio Nodes

#### Oscillator Node
Generates periodic waveforms (sine, square, sawtooth, triangle).

```javascript
const oscillator = audioContext.createOscillator();
oscillator.type = 'sine'; // 'sine', 'square', 'sawtooth', 'triangle'
oscillator.frequency.value = 440; // Hz (A4 note)
oscillator.connect(audioContext.destination);
oscillator.start(audioContext.currentTime);
oscillator.stop(audioContext.currentTime + 1.0); // Stop after 1 second
```

**Waveform characteristics:**
- **sine**: Pure tone, smooth, musical
- **square**: Hollow, clarinet-like, retro/8-bit sound
- **sawtooth**: Bright, brassy, rich in harmonics
- **triangle**: Softer than square, mellow

#### Gain Node
Controls volume/amplitude.

```javascript
const gainNode = audioContext.createGain();
gainNode.gain.value = 0.5; // 50% volume (0.0 to 1.0+)

// Connect: source → gain → destination
oscillator.connect(gainNode);
gainNode.connect(audioContext.destination);
```

#### Biquad Filter Node
Filters frequencies (lowpass, highpass, bandpass, etc.).

```javascript
const filter = audioContext.createBiquadFilter();
filter.type = 'lowpass'; // 'lowpass', 'highpass', 'bandpass', 'notch', 'allpass', 'peaking', 'lowshelf', 'highshelf'
filter.frequency.value = 1000; // Cutoff frequency in Hz
filter.Q.value = 1; // Quality factor (resonance)

oscillator.connect(filter);
filter.connect(audioContext.destination);
```

**Filter types:**
- **lowpass**: Cuts high frequencies, sounds muffled/warm
- **highpass**: Cuts low frequencies, sounds thin/bright
- **bandpass**: Only allows frequencies near cutoff, telephone-like
- **notch**: Removes frequencies near cutoff
- **peaking**: Boosts/cuts frequencies at cutoff (use gain)
- **lowshelf/highshelf**: Boosts/cuts all frequencies above/below cutoff

#### Noise Generation
Web Audio doesn't have a built-in noise generator. Use a buffer with random values:

```javascript
function createWhiteNoiseBuffer(duration) {
    const sampleRate = audioContext.sampleRate;
    const bufferSize = sampleRate * duration;
    const buffer = audioContext.createBuffer(1, bufferSize, sampleRate);
    const data = buffer.getChannelData(0);

    for (let i = 0; i < bufferSize; i++) {
        data[i] = Math.random() * 2 - 1; // Random values between -1 and 1
    }

    return buffer;
}

const noiseBuffer = createWhiteNoiseBuffer(2.0); // 2 seconds
const noiseSource = audioContext.createBufferSource();
noiseSource.buffer = noiseBuffer;
noiseSource.connect(audioContext.destination);
noiseSource.start();
```

#### Delay Node
Creates echo/delay effects.

```javascript
const delay = audioContext.createDelay();
delay.delayTime.value = 0.5; // Delay in seconds

const feedback = audioContext.createGain();
feedback.gain.value = 0.4; // Feedback amount

// Create feedback loop: source → delay → feedback → delay
source.connect(delay);
delay.connect(feedback);
feedback.connect(delay);
delay.connect(audioContext.destination);
```

#### Convolver Node
Used for reverb and complex impulse responses.

```javascript
const convolver = audioContext.createConvolver();
// convolver.buffer = impulseResponseBuffer; // Load an impulse response
source.connect(convolver);
convolver.connect(audioContext.destination);
```

#### Stereo Panner Node
Positions sound in stereo field.

```javascript
const panner = audioContext.createStereoPanner();
panner.pan.value = -1; // -1 (left) to 1 (right), 0 is center
source.connect(panner);
panner.connect(audioContext.destination);
```

### Audio Parameters and Automation

Audio parameters (like `frequency`, `gain.value`, `detune`) can be automated over time using these methods:

#### setValueAtTime
Set a value at a specific time.

```javascript
gainNode.gain.setValueAtTime(0.5, audioContext.currentTime + 1.0);
```

#### linearRampToValueAtTime
Linear transition to a value.

```javascript
// Fade in over 2 seconds
gainNode.gain.setValueAtTime(0, audioContext.currentTime);
gainNode.gain.linearRampToValueAtTime(1, audioContext.currentTime + 2.0);
```

#### exponentialRampToValueAtTime
Exponential transition (more natural for pitch and volume). **Value cannot be 0**.

```javascript
// Pitch glide
oscillator.frequency.setValueAtTime(880, audioContext.currentTime);
oscillator.frequency.exponentialRampToValueAtTime(440, audioContext.currentTime + 1.0);
```

#### setTargetAtTime
Exponential approach to target value with time constant.

```javascript
// Smooth decay with time constant of 0.1 seconds
gainNode.gain.setTargetAtTime(0, audioContext.currentTime, 0.1);
```

#### setValueCurveAtTime
Custom curve defined by an array of values.

```javascript
const curve = new Float32Array([0, 0.5, 1.0, 0.5, 0]);
gainNode.gain.setValueCurveAtTime(curve, audioContext.currentTime, 1.0);
```

### ADSR Envelope (Attack, Decay, Sustain, Release)

Standard envelope shape used in synthesizers:

```javascript
function applyADSR(param, startTime, attack, decay, sustain, release, duration) {
    const attackEnd = startTime + attack;
    const decayEnd = attackEnd + decay;
    const releaseStart = startTime + duration - release;

    // Attack: 0 → 1
    param.setValueAtTime(0, startTime);
    param.linearRampToValueAtTime(1, attackEnd);

    // Decay: 1 → sustain level
    param.linearRampToValueAtTime(sustain, decayEnd);

    // Sustain: hold at sustain level
    param.setValueAtTime(sustain, releaseStart);

    // Release: sustain → 0
    param.linearRampToValueAtTime(0, releaseStart + release);
}

// Example: Apply to gain
const gainNode = audioContext.createGain();
applyADSR(
    gainNode.gain,
    audioContext.currentTime,
    0.01,  // attack: 10ms
    0.1,   // decay: 100ms
    0.7,   // sustain: 70%
    0.3,   // release: 300ms
    1.0    // total duration: 1 second
);
```

### Musical Note Frequencies

Common notes in Hz (A4 = 440 Hz standard):

```javascript
const notes = {
    // Octave 3
    'C3': 130.81, 'C#3': 138.59, 'D3': 146.83, 'D#3': 155.56,
    'E3': 164.81, 'F3': 174.61, 'F#3': 185.00, 'G3': 196.00,
    'G#3': 207.65, 'A3': 220.00, 'A#3': 233.08, 'B3': 246.94,

    // Octave 4 (Middle C is C4)
    'C4': 261.63, 'C#4': 277.18, 'D4': 293.66, 'D#4': 311.13,
    'E4': 329.63, 'F4': 349.23, 'F#4': 369.99, 'G4': 392.00,
    'G#4': 415.30, 'A4': 440.00, 'A#4': 466.16, 'B4': 493.88,

    // Octave 5
    'C5': 523.25, 'C#5': 554.37, 'D5': 587.33, 'D#5': 622.25,
    'E5': 659.25, 'F5': 698.46, 'F#5': 739.99, 'G5': 783.99,
    'G#5': 830.61, 'A5': 880.00, 'A#5': 932.33, 'B5': 987.77,

    // Octave 6
    'C6': 1046.50, 'C#6': 1108.73, 'D6': 1174.66, 'D#6': 1244.51,
    'E6': 1318.51, 'F6': 1396.91, 'F#6': 1479.98, 'G6': 1567.98,
    'G#6': 1661.22, 'A6': 1760.00, 'A#6': 1864.66, 'B6': 1975.53
};

// Calculate frequency from MIDI note number
function midiToFreq(midiNote) {
    return 440 * Math.pow(2, (midiNote - 69) / 12);
}
```

### Timing and Scheduling

**Use `audioContext.currentTime` for precise timing** instead of `setTimeout` or `setInterval`.

```javascript
const now = audioContext.currentTime;

// Schedule notes precisely
playNote(440, now);        // A4 immediately
playNote(554, now + 0.5);  // C#5 after 0.5 seconds
playNote(659, now + 1.0);  // E5 after 1 second
```

### Creating Reusable Audio Functions

```javascript
function playTone(frequency, duration, startTime = audioContext.currentTime) {
    const osc = audioContext.createOscillator();
    const gain = audioContext.createGain();

    osc.frequency.value = frequency;
    osc.connect(gain);
    gain.connect(audioContext.destination);

    // Quick fade in/out to avoid clicks
    gain.gain.setValueAtTime(0, startTime);
    gain.gain.linearRampToValueAtTime(0.3, startTime + 0.01);
    gain.gain.linearRampToValueAtTime(0, startTime + duration);

    osc.start(startTime);
    osc.stop(startTime + duration);
}
```

### Complete HTML Template

```html
<!DOCTYPE html>
<html>
<head>
    <title>Web Audio Example</title>
</head>
<body>
    <button id="playBtn">Play Sound</button>

    <script>
        let audioContext;

        // Initialize on user interaction (required by browsers)
        document.getElementById('playBtn').addEventListener('click', () => {
            if (!audioContext) {
                audioContext = new (window.AudioContext || window.webkitAudioContext)();
            }

            // Your audio code here
            const osc = audioContext.createOscillator();
            const gain = audioContext.createGain();

            osc.connect(gain);
            gain.connect(audioContext.destination);

            osc.frequency.value = 440;
            gain.gain.value = 0.3;

            const now = audioContext.currentTime;
            osc.start(now);
            osc.stop(now + 0.5);
        });
    </script>
</body>
</html>
```

### Performance Tips

1. **Reuse nodes when possible** - Creating many nodes can impact performance
2. **Avoid clicks** - Always fade in/out to avoid audible pops
3. **Cleanup** - Disconnect and stop nodes when done
4. **Sample rate** - Default is 48000 Hz, can be changed during context creation
5. **Latency** - Use `audioContext.baseLatency` and `audioContext.outputLatency` to compensate for system latency

### Browser Compatibility Notes

- Most modern browsers support Web Audio API
- Requires user interaction to start (autoplay policy)
- Use vendor prefixes for older browsers: `webkitAudioContext`
- Some mobile browsers have limitations on simultaneous sounds
