using Godot;

[Tool]
public class ParticleSystemColorOverLife : ParticleSystemModule {
    [Export]
    public Gradient gradient;

    public override void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {
        if (gradient == null) return;
        p.color = p.baseColor * gradient.Interpolate(1f - p.life);
    }
}