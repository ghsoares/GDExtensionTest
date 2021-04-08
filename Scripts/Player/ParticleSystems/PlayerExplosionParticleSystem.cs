using System.Collections.Generic;
using Godot;

public class PlayerExplosionParticleSystem : ParticleSystem {
    [Export] public int amount = 32;
    [Export] public float radius = 8f;
    [Export] public Vector2 velocityRange = new Vector2(64f, 128f);
    [Export] public Vector2 sizeRange = Vector2.One * 4f;
    [Export] public Vector2 lifetimeRange = Vector2.One;
    [Export] public Curve dragCurve;
    [Export] public Vector2 dragRange = new Vector2(0f, 10f);

    public void Emit() {
        for (int i = 0; i < amount; i++) {
            EmitParticle();
        }
    }

    protected override void InitParticle(Particle particle, Dictionary<string, object> overrideParams)
    {
        base.InitParticle(particle, overrideParams);
        Vector2 v = Vector2.Right.Rotated(GD.Randf() * Mathf.Pi * 2f);

        Color c = particle.customDataVertex;
        c.r = particle.position.x;
        c.g = -particle.position.y;
        particle.customDataVertex = c;

        particle.position += v * radius;
        particle.velocity += v * (float)GD.RandRange(velocityRange.x, velocityRange.y);
        particle.size *= (float)GD.RandRange(sizeRange.x, sizeRange.y);
        particle.life *= (float)GD.RandRange(lifetimeRange.x, lifetimeRange.y);

        particle.gravityScale *= (float)GD.RandRange(.25f, 1f);
    }

    protected override void UpdateParticle(Particle particle, float delta)
    {
        base.UpdateParticle(particle, delta);
        float lifeT = particle.life / particle.lifetime;
        if (dragCurve != null) {
            float drag = dragCurve.Interpolate(lifeT);
            drag = Mathf.Lerp(dragRange.x, dragRange.y, drag);
            particle.velocity -= particle.velocity * Mathf.Min(drag * delta, 1f);
        }
        Color c = particle.customDataVertex;
        c.b = particle.position.x;
        c.a = -particle.position.y;
        particle.customDataVertex = c;
    }
}