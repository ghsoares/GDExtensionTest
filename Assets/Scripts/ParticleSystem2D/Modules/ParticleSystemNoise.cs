using Godot;

[Tool]
public class ParticleSystemNoise : ParticleSystemModule {
    private FastNoiseLite noise {get; set;}
    private float noiseOff {get; set;}

    [Export]
    public float strength = 1f;
    [Export]
    public float frequency = .5f;
    [Export]
    public float scrollSpeed = 0f;
    [Export]
    public int octaves = 1;
    [Export]
    public float octaveLacunarity = 2f;
    [Export]
    public float octaveGain = .5f;
    [Export]
    public bool overLife = false;
    [Export]
    public Curve overLifeCurve;

    private void ResetNoiseIfNeeded() {
        bool reset = false;

        if (noise == null) {
            reset = true;
        } else {
            bool diffOctaves = noise.GetFractalOctaves() != octaves;
            bool diffLacunarity = noise.GetFractalLacunarity() != octaveLacunarity;
            bool diffGain = noise.GetFractalGain() != octaveGain;
            reset = diffOctaves || diffLacunarity || diffGain;
        }
        
        if (reset) {
            noise = new FastNoiseLite();
            noise.SetFractalOctaves(octaves);
            noise.SetFractalLacunarity(octaveLacunarity);
            noise.SetFractalGain(octaveGain);
            noiseOff = 0f;
        } 
    }

    public override void UpdateModule(float delta) {
        noiseOff += scrollSpeed * delta;
    }

    public override void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {
        ResetNoiseIfNeeded();

        float a = noise.GetNoise(
            p.position.x * frequency,
            p.position.y * frequency,
            noiseOff
        ) * Mathf.Pi * 2f;
        Vector2 v = Vector2.Right.Rotated(a) * strength;

        if (overLife && overLifeCurve != null) {
            float t = p.currentLife / p.lifetime;
            v *= overLifeCurve.Interpolate(1f - t);
        }

        p.velocity += v * delta;
    }
}