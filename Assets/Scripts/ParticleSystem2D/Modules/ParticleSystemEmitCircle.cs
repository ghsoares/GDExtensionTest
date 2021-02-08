using Godot;
using ExtensionMethods.RandomMethods;

[Tool]
public class ParticleSystemEmitCircle : ParticleSystemModule {
    [Export]
    public float radius = 5f;
    [Export(PropertyHint.Range, "0,1")]
    public float radiusThickness = 1f;

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams) {
        System.Random r = particleSystem.random;

        float a = r.NextFloat(0f, Mathf.Pi * 2f);
        float o = r.NextFloat(1f - radiusThickness, 1f) * radius;

        Vector2 off = Vector2.Right.Rotated(a) * o;
        Vector2 dir = off.Normalized();

        p.position += off;
        p.velocity = dir * p.velocity.Length();
    }
}