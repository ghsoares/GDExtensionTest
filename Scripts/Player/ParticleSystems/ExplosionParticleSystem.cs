using Godot;
using ParticleSystem;
using System;

[Tool]
public class ExplosionParticleSystem : BurstParticleSystem
{
    [Export] public Curve sizeVariation;
    [Export] public float velocity = 1f;
    [Export] public Curve velocityVariation;
    [Export] public float drag = 1f;
    [Export] public Curve overLifeDrag;

    protected override void InitParticle(Particle particle)
    {
        base.InitParticle(particle);

        if (sizeVariation != null) {
            particle.scale *= sizeVariation.Interpolate(GD.Randf());
        }

        Vector3 vel = Vector3.Down;
        vel = new Quat(new Vector3(
            GD.Randf() * Mathf.Pi * 4f, GD.Randf() * Mathf.Pi * 4f, 0f
        )).Xform(vel);
        
        vel *= velocity;
        if (velocityVariation != null) {
            vel *= velocityVariation.Interpolate(GD.Randf());
        }

        particle.velocity += vel;
    }

    protected override void UpdateParticle(Particle particle, float delta)
    {
        base.UpdateParticle(particle, delta);

        float lifeT = particle.life / particle.lifetime;

        float d = drag;

        if (overLifeDrag != null) {
            d *= overLifeDrag.Interpolate(1f - lifeT);
        }

        particle.velocity -= particle.velocity * Mathf.Clamp(d * delta, 0f, 1f);

        Vector3 diff = particle.position - particle.startPosition;

        Color c = particle.custom;

        c.r = diff.x;
        c.g = diff.y;
        c.b = diff.z;

        particle.custom = c;
    }
}
