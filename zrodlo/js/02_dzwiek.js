// ==================== 2. WEB AUDIO SYNTHESIZER ====================
class SoundFX {
    constructor() { this.ctx = null; this.muted = false; }
    init() {
        if (!this.ctx) {
            const AC = window.AudioContext || window.webkitAudioContext;
            if (AC) this.ctx = new AC();
        }
        if (this.ctx && this.ctx.state === 'suspended') this.ctx.resume().catch(() => {});
    }
    toggleMute() {
        this.muted = !this.muted;
        document.getElementById('btn-mute-hub').textContent = this.muted ? '🔇' : '🔊';
        document.getElementById('btn-mute-raid').textContent = this.muted ? '🔇' : '🔊';
    }
    noise(dur, freq, gainVal, type = 'bandpass', drop = true) {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;
        const buf = this.ctx.createBuffer(1, Math.floor(this.ctx.sampleRate * dur), this.ctx.sampleRate);
        const d = buf.getChannelData(0);
        for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
        const src = this.ctx.createBufferSource();
        src.buffer = buf;
        const f = this.ctx.createBiquadFilter();
        f.type = type;
        f.frequency.setValueAtTime(freq, now);
        if (drop) f.frequency.exponentialRampToValueAtTime(140, now + dur);
        const g = this.ctx.createGain();
        g.gain.setValueAtTime(gainVal, now);
        g.gain.exponentialRampToValueAtTime(0.001, now + dur);
        src.connect(f); f.connect(g); g.connect(this.ctx.destination);
        src.start(now); src.stop(now + dur);
    }
    tone(f1, f2, dur, type = 'triangle', gainVal = 0.12) {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        osc.type = type;
        osc.frequency.setValueAtTime(f1, now);
        osc.frequency.exponentialRampToValueAtTime(Math.max(25, f2), now + dur);
        const g = this.ctx.createGain();
        g.gain.setValueAtTime(gainVal, now);
        g.gain.exponentialRampToValueAtTime(0.001, now + dur);
        osc.connect(g); g.connect(this.ctx.destination);
        osc.start(now); osc.stop(now + dur);
    }
    swing(heavy = false) {
        this.noise(heavy ? 0.22 : 0.14, heavy ? 520 : 880, heavy ? 0.22 : 0.15, 'bandpass', true);
        this.tone(heavy ? 180 : 280, 90, heavy ? 0.16 : 0.10, 'triangle', 0.08);
    }
    hitFlesh() {
        this.noise(0.09, 650, 0.22, 'lowpass', true);
        this.tone(160, 55, 0.10, 'sawtooth', 0.16);
    }
    block() {
        this.noise(0.11, 1400, 0.22, 'bandpass', true);
        this.tone(420, 210, 0.12, 'square', 0.12);
    }
    parryClang() {
        // Resonant soulsborne metallic parry chime!
        this.tone(1320, 1280, 0.42, 'sine', 0.22);
        this.tone(1980, 1920, 0.36, 'triangle', 0.16);
        this.tone(2640, 2400, 0.24, 'sine', 0.10);
        this.noise(0.12, 3200, 0.24, 'highpass', false);
    }
    riposte() {
        this.tone(220, 60, 0.30, 'sawtooth', 0.26);
        this.tone(880, 440, 0.22, 'triangle', 0.16);
        this.noise(0.18, 1200, 0.28, 'lowpass', true);
    }
    bowRelease() {
        this.tone(440, 190, 0.12, 'triangle', 0.14);
        this.noise(0.07, 1800, 0.10, 'highpass', true);
    }
    dodge() { this.noise(0.14, 480, 0.12, 'lowpass', true); }
    step() { this.noise(0.04, 340, 0.045, 'lowpass', false); }
    hurt() { this.tone(135, 50, 0.20, 'sawtooth', 0.20); }
    drink() {
        this.tone(360, 540, 0.14, 'sine', 0.10);
        setTimeout(() => this.tone(540, 740, 0.18, 'sine', 0.10), 130);
    }
    loot() { this.tone(580, 880, 0.10, 'triangle', 0.09); }
    ui() { this.tone(420, 320, 0.04, 'triangle', 0.05); }
    extractTick() { this.tone(528, 528, 0.10, 'sine', 0.09); }
    extractDone() {
        this.tone(392, 523, 0.24, 'triangle', 0.13);
        setTimeout(() => this.tone(523, 784, 0.40, 'triangle', 0.15), 180);
    }
}
const SFX = new SoundFX();
