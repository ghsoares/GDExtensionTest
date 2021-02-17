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
    [Export]
    public bool overrideLifetime = false;
    [Export]
    public Vector2 lifetimeRange = Vector2.One;

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams) {
        float s = Mathf.Sign(GD.Randf() * 2f - 1f);

        float o = GD.Randf();
        Vector2 dir = Vector2.Up.Rotated(particleSystem.rot + Mathf.Deg2Rad(rotation) + Mathf.Deg2Rad(
            Mathf.Lerp(directionRotationRange.x, directionRotationRange.y, o) * s
        ));
        Vector2 off = Vector2.Right.Rotated(particleSystem.rot + Mathf.Deg2Rad(rotation)) * o * s * size;

        p.position += off;
        p.velocity = dir * p.velocity.Length();

        if (overrideLifetime) {
            float l = Mathf.Lerp(lifetimeRange.x, lifetimeRange.y, o);
            p.lifetime = l;
            p.currentLife = l;
        }
    }
}
