using Godot;
using System;
using ExtensionMethods.RandomMethods;

[Tool]
public class EmitPlane : ParticleSystemModule
{
    [Export]
    public float size = 2f;
    [Export]
    public float sizeThickness = 1f;
    [Export]
    public float rotation = 0f;
    [Export]
    public Vector2 directionRotationRange = Vector2.Zero;

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams) {
        FastNoiseLite r = particleSystem.noiseRandom;

        float s = Mathf.Sign(r.GetNoise(p.idx, 0));

        float o = r.GetNoiseUnsigned(p.idx, 1);
        Vector2 dir = Vector2.Up.Rotated(particleSystem.GlobalRotation + Mathf.Deg2Rad(rotation) + Mathf.Deg2Rad(
            Mathf.Lerp(directionRotationRange.x, directionRotationRange.y, o) * s
        ));
        Vector2 off = Vector2.Right.Rotated(particleSystem.GlobalRotation + Mathf.Deg2Rad(rotation)) * o * s * size;

        p.position += off;
        p.velocity = dir * p.velocity.Length();
    }
}
