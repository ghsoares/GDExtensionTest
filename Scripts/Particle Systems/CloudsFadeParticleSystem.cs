using System.Collections.Generic;
using Godot;

public class CloudsFadeParticleSystem : ParticleSystem
{
    float currentRate = 0f;

    [Export] public float rate = 32f;
    [Export] public float spreadRadius = 1f;
    [Export] public float inheritVelocityMultiply = .1f;
    [Export] public float maxVelocity = 32f;
    [Export] public Vector2 sizeRange = Vector2.One * 4f;
    [Export] public Vector2 lifetimeRange = Vector2.One;

    public override void _Ready()
    {
        base._Ready();
    }

    protected override void UpdateSystem(float delta)
    {
        base.UpdateSystem(delta);
        currentRate += delta * rate;
        while (currentRate >= 1f) {
            EmitParticle();
            currentRate -= 1f;
        }
    }

    protected override void InitParticle(Particle particle, Dictionary<string, object> overrideParams)
    {
        base.InitParticle(particle, overrideParams);
        float angle = GD.Randf() * Mathf.Pi * 4f;
        Vector2 v = Vector2.Right.Rotated(angle);

        float vel = currentVelocityLength * inheritVelocityMultiply;
        vel = Mathf.Clamp(vel, 0f, maxVelocity);

        particle.position += v * spreadRadius;
        particle.velocity += v * vel * GD.Randf();
        particle.size *= (float)GD.RandRange(sizeRange.x, sizeRange.y);
        particle.life *= (float)GD.RandRange(lifetimeRange.x, lifetimeRange.y);
    }
}