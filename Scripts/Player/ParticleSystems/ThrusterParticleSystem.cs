using Godot;
using ParticleSystem;

[Tool]
public class ThrusterParticleSystem : EmissionParticleSystem {
    [Export] public Vector3 dir = Vector3.Down;
    [Export] public float spread = 15f;
    [Export] public float velocity = 1f;
    [Export] public Curve velocityVariation;
    [Export] public bool transformDir = true;

    protected override void InitParticle(Particle particle)
    {
        base.InitParticle(particle);

        Vector3 vel = dir;
        vel = new Quat(new Vector3(
            Mathf.Deg2Rad(spread) * GD.Randf(), GD.Randf() * Mathf.Pi * 4f, 0f
        )).Xform(vel);
        
        vel *= velocity;
        if (velocityVariation != null) {
            vel *= velocityVariation.Interpolate(GD.Randf());
        }

        if (transformDir) vel = GlobalTransform.basis.Xform(vel);

        particle.velocity += vel;
    }
}