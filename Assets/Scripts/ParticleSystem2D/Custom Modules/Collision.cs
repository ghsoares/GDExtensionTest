using Godot;
using System;

[Tool]
public class Collision : ParticleSystemModule
{
    public Godot.Collections.Array excludeBodies {get; private set;}

    [Export]
    public float sizeScale = .5f;
    [Export(PropertyHint.Range, "0,1")]
    public float bounciness = 0f;

    public override void InitModule() {
        if (excludeBodies == null) excludeBodies = new Godot.Collections.Array();
    }

    public override void UpdateModule(float delta) {
        if (excludeBodies == null) excludeBodies = new Godot.Collections.Array();
    }

    public override void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {
        Vector2 dir = p.velocity.Normalized();
        float l = p.velocity.Length() * delta + sizeScale;
        var res = spaceState.IntersectRay(p.position, p.position + dir * l, excludeBodies);
        if (res.Count == 0) return;

        Vector2 point = (Vector2)res["position"];
        Vector2 normal = (Vector2)res["normal"];
        normal = normal.Normalized();

        if (!normal.IsNormalized()) return;

        p.position = point + normal * (sizeScale * p.size * 1.08f);
        p.velocity = p.velocity.Slide(normal);
        p.velocity = p.velocity.LinearInterpolate(p.velocity.Bounce(normal), bounciness);
    }
}
