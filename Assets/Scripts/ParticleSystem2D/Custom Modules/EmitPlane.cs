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
    public Vector2 direction = Vector2.Zero;
    [Export]
    public float directionRotation = 0f;

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams) {
        System.Random r = particleSystem.random;

        float s = r.NextFloat() < .5f ? -1f : 1f;

        float a = Mathf.Pi / 2f * s + Mathf.Deg2Rad(rotation);
        float o = r.NextFloat(1f - sizeThickness, 1f) * size;

        Vector2 off = emitParams.shapeDirection.Rotated(particleSystem.GlobalRotation + a) * o;
        Vector2 dir = off.Normalized();
        if (direction != Vector2.Zero) {
            dir = direction.Rotated(particleSystem.GlobalRotation + Mathf.Deg2Rad(directionRotation));
        }

        p.position += off;
        p.velocity = dir * p.velocity.Length();
    }
}
