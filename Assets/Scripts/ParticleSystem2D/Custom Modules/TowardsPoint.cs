using Godot;
using System;

[Tool]
public class TowardsPoint : ParticleSystemModule
{
    [Export]
    public Vector2 point;
    [Export]
    public float lerping = .1f;
    [Export]
    public bool kill = true;

    public override void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {
        Vector2 prevDir = (point - p.prevPosition).Normalized();
        Vector2 off = (point - p.position);
        Vector2 dir = off.Normalized();
        Vector2 currDir = p.velocity.Normalized();
        float spd = p.velocity.Length();

        currDir = currDir.Slerp(dir, Mathf.Clamp(lerping * delta, 0, 1));

        p.velocity = currDir * spd;

        if (prevDir.Dot(dir) < 0f && kill) {
            p.currentLife = 0f;
        }
    }
}
