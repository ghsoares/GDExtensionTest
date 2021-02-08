using Godot;

[Tool]
public class ParticleSystemInheritVelocity : ParticleSystemModule {
    [Export]
    public float percentage = 1f;

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams) {
        p.velocity += particleSystem.currentVelocity * percentage;
    }
}