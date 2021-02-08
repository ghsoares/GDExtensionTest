using Godot;

[Tool]
public class ParticleSystemSizeOverLife : ParticleSystemModule {
    [Export]
    public Curve curve;
    [Export]
    public float sizeMultiplier = 1f;

    public override void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {
        if (curve == null) return;
        float s = curve.Interpolate(1f - p.life) * sizeMultiplier;
        p.size = p.baseSize * s;
    }
}