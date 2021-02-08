using Godot;

[Tool]
public class ParticleSystemUpdateParticle : ParticleSystemModule {
    public override void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {
        p.currentLife -= delta;
        p.currentLife = Mathf.Max(p.currentLife, 0f);
        p.velocity += particleSystem.gravity * delta;
        p.position += p.velocity * delta;
    }
}