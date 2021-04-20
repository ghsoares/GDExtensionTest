using System.Collections.Generic;
using Godot;

public class PlayerRocketParticleSystem : ParticleSystem
{
    float currentRate = 0f;

    [Export] public float emissionRate = 64f;
    [Export] public float spreadRadius = 1f;
    [Export] public Vector2 spreadAngleRange = new Vector2(0f, 15f);
    [Export] public Vector2 direction = Vector2.Down;
    [Export] public Vector2 velocityRange = Vector2.One * 256f;
    [Export] public Vector2 sizeRange = Vector2.One * 4f;
    [Export] public Vector2 lifetimeRange = Vector2.One;

    protected override void EmissionProcess(float delta)
    {
        base.EmissionProcess(delta);
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
        float angle = (float)GD.RandRange(spreadAngleRange.x, spreadAngleRange.y);
        angle *= (particle.idx % 2) * 2f - 1f;
        Vector2 v = direction.Rotated(Mathf.Deg2Rad(angle));

        particle.position += v * spreadRadius;
        particle.velocity += v * (float)GD.RandRange(velocityRange.x, velocityRange.y) * velocityMultiply;
        particle.size *= (float)GD.RandRange(sizeRange.x, sizeRange.y);
        particle.life *= (float)GD.RandRange(lifetimeRange.x, lifetimeRange.y);
    }
}