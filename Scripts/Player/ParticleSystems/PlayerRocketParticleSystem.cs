using System.Collections.Generic;
using Godot;

public class PlayerRocketParticleSystem : ParticleSystem
{
    float currentRate = 0f;

    [Export] public float emissionRate = 64f;
    [Export] public float spreadRadius = 1f;
    [Export] public float spreadAngle = 15f;
    [Export] public Vector2 direction = Vector2.Down;
    [Export] public Vector2 velocityRange = Vector2.One * 256f;
    [Export] public Vector2 sizeRange = Vector2.One * 4f;
    [Export] public Vector2 lifetimeRange = Vector2.One;

    protected override void UpdateSystem(float delta)
    {
        base.UpdateSystem(delta);
        currentRate += delta * emissionRate;

        while (currentRate >= 1f)
        {
            currentRate -= 1f;
            EmitParticle();
        }
    }

    protected override void InitParticle(Particle particle, Dictionary<string, object> overrideParams)
    {
        base.InitParticle(particle, overrideParams);
        Vector2 v = direction.Rotated(Mathf.Deg2Rad((float)GD.RandRange(-spreadAngle, spreadAngle)) / 2f);

        particle.position += v * spreadRadius;
        particle.velocity += v * (float)GD.RandRange(velocityRange.x, velocityRange.y) * velocityMultiply;
        particle.size *= (float)GD.RandRange(sizeRange.x, sizeRange.y);
        particle.life *= (float)GD.RandRange(lifetimeRange.x, lifetimeRange.y);
    }
}