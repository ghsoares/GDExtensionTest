using Godot;

[Tool]
public class ParticleSystemLimitVelocity : ParticleSystemModule {
    [Export]
    public float drag = 8f;

    public override void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {
        Vector2 totalDrag = p.velocity * Mathf.Clamp(drag * delta, 0, 1);
        p.velocity -= totalDrag;
    }
}