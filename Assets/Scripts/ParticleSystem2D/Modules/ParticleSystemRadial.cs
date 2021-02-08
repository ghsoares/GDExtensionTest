using Godot;

[Tool]
public class ParticleSystemRadial : ParticleSystemModule {
    [Export]
    public float speed = 8f;

    public override void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {
        Vector2 diff = p.position - particleSystem.pos;
        Vector2 dir = diff.Normalized();
        p.position += dir * speed * delta;
    }
}