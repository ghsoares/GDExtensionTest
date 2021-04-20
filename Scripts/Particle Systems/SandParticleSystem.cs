using ExtensionMethods.DictionaryExtensions;
using Godot;
using System;
using System.Collections.Generic;

public class SandParticleSystem : ParticleSystem
{
    float currentRate = 0f;

    [Export] public float radius = 8f;
    [Export] public Vector2 velocityRange = new Vector2(64f, 128f);
    [Export] public Vector2 sizeRange = Vector2.One * 4f;
    [Export] public Vector2 lifetimeRange = Vector2.One;

    protected override void InitParticle(Particle particle, Dictionary<string, object> overrideParams)
    {
        base.InitParticle(particle, overrideParams);

        float spread = (float)overrideParams.Get("spread", 0f);
        particle.position += Vector2.Right * (float)GD.RandRange(-spread / 2f, spread / 2f);
        float y = Planet.instance.terrain.GetTerrainY(particle.position.x);

        particle.position = new Vector2(particle.position.x, y);

        Vector2 v = Vector2.Right.Rotated(GD.Randf() * Mathf.Pi * 2f);

        particle.position += v * radius;
        particle.velocity += v * (float)GD.RandRange(velocityRange.x, velocityRange.y);
        particle.size *= (float)GD.RandRange(sizeRange.x, sizeRange.y);
        particle.life *= (float)GD.RandRange(lifetimeRange.x, lifetimeRange.y);
    }

    public void AddRate(float rate, Dictionary<string, object> overrideParams) {
        currentRate += rate;
        while (currentRate >= 1f) {
            EmitParticle(overrideParams);
            currentRate -= 1f;
        }
    }
}
