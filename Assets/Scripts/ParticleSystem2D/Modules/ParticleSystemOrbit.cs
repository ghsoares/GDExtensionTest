using Godot;

[Tool]
public class ParticleSystemOrbit : ParticleSystemModule {
    [Export]
    public float speed = 10f;

    public override void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {
        Vector2 diff = p.position - particleSystem.pos;
        diff = diff.Rotated(Mathf.Deg2Rad(speed * delta));
        p.position = particleSystem.pos + diff;
    }
}