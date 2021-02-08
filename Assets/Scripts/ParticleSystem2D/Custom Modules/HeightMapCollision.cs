using Godot;
using System;

public class HeightMapCollision : ParticleSystemModule
{
    [Export]
    public float sizeOffset = .5f;
    [Export(PropertyHint.Range, "0,1")]
    public float bounciness = 0f;

    public override void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {
        if (Game.main == null) return;

        float pY = p.position.y;
        pY += p.size * sizeOffset;

        float h = Game.main.terrainSize.y - Game.main.SampleHeight(p.position.x);
        float diff = h - pY;

        if (diff <= 0f) {
            Vector2 normal = Game.main.SampleNormal(p.position.x);
            p.position -= Vector2.Up * diff;
            p.velocity = p.velocity.Slide(normal);
            p.velocity = p.velocity.LinearInterpolate(p.velocity.Bounce(normal), bounciness);
        }
    }
}
