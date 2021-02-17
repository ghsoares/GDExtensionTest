using Godot;
using ExtensionMethods.RandomMethods;

[Tool]
public class ParticleSystemEmitCone : ParticleSystemModule {
    [Export]
    public float radius = 5f;
    [Export(PropertyHint.Range, "0,1")]
    public float radiusThickness = 1f;
    [Export]
    public float coneAngle = 25f;
    [Export]
    public float rotation = 0f;

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams) {        
        if (radius <= 0f) radius = .01f;

        float a = (GD.Randf() * 2f - 1f) * Mathf.Deg2Rad(coneAngle) + Mathf.Deg2Rad(rotation);
        float o = Mathf.Lerp(
            1f - radiusThickness, 1f, GD.Randf()
        ) * radius;

        /*float a = r.NextFloat(-Mathf.Deg2Rad(coneAngle), Mathf.Deg2Rad(coneAngle)) + Mathf.Deg2Rad(rotation);
        float o = r.NextFloat(1f - radiusThickness, 1f) * radius;*/

        Vector2 off = emitParams.shapeDirection.Rotated(particleSystem.rot + a) * o;
        Vector2 dir = off.Normalized();

        p.position += off;
        p.velocity = dir * p.velocity.Length();
    }
}