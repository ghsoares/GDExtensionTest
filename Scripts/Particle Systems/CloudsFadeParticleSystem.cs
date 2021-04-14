using System.Collections.Generic;
using Godot;

public class CloudsFadeParticleSystem : ParticleSystem
{
    Vector2 trailPrevPos;

    [Export] public float ratePerDistance = .1f;
    [Export] public float spreadRadius = 1f;
    [Export] public Vector2 velocityRange = Vector2.One * 256f;
    [Export] public Vector2 sizeRange = Vector2.One * 4f;
    [Export] public Vector2 lifetimeRange = Vector2.One;

    public override void _Ready()
    {
        base._Ready();
        trailPrevPos = GlobalPosition;
    }

    protected override void UpdateSystem(float delta)
    {
        base.UpdateSystem(delta);
        Vector2 curr = GlobalPosition;
        Vector2 deltaOff = (curr - trailPrevPos);
        float deltaLen = deltaOff.Length();

        float deltaS = 1f / ratePerDistance;

        if (deltaLen > deltaS)
        {
            Dictionary<string, object> emitParams = new Dictionary<string, object>();
            for (float s = deltaS; s < deltaLen; s += deltaS) {
                float t = s / deltaLen;
                Vector2 pos = prevPos.LinearInterpolate(curr, t);

                emitParams["position"] = pos;

                EmitParticle(emitParams);
            }
            trailPrevPos = curr;
        }
    }

    protected override void InitParticle(Particle particle, Dictionary<string, object> overrideParams)
    {
        base.InitParticle(particle, overrideParams);
        float angle = GD.Randf() * Mathf.Pi * 4f;
        Vector2 v = Vector2.Right.Rotated(angle);

        particle.position += v * spreadRadius;
        particle.velocity += v * (float)GD.RandRange(velocityRange.x, velocityRange.y) * velocityMultiply;
        particle.size *= (float)GD.RandRange(sizeRange.x, sizeRange.y);
        particle.life *= (float)GD.RandRange(lifetimeRange.x, lifetimeRange.y);
    }
}