using Godot;
using System;

[Tool]
public class EmitTrail : ParticleSystemModule
{
    private ParticleSystem2D _particleSystemTrail {get; set;}

    private ParticleSystem2D particleSystemTrail {
        get {
            if (_particleSystemTrail == null || this.GetPathTo(_particleSystemTrail) != particleSystemTrailPath) {
                if (particleSystemTrailPath == null) {
                    _particleSystemTrail = null;
                } else {
                    _particleSystemTrail = GetNodeOrNull(particleSystemTrailPath) as ParticleSystem2D;
                }
            }
            return _particleSystemTrail;
        }
    }

    [Export]
    public float rate = .1f;
    [Export]
    public NodePath particleSystemTrailPath;

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams) {
        p.customData["TrailPrevPos"] = p.position;
    }

    public override void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {
        if (!p.customData.ContainsKey("TrailPrevPos")) return;
        if (particleSystemTrail == null) return;

        Vector2 prevPos = (Vector2)p.customData["TrailPrevPos"];
        Vector2 curr = p.position;
        Vector2 deltaPos = curr - prevPos;
        float dist = deltaPos.Length();
        float deltaS = 1f / rate;

        if (dist >= deltaS) {
            for (float s = deltaS; s < dist; s += deltaS) {
                float t = s / dist;
                Vector2 pos = prevPos.LinearInterpolate(curr, t);
                particleSystemTrail.Emit(new ParticleSystem2D.EmitParams {
                    position = pos
                });
            }
            p.customData["TrailPrevPos"] = curr;
        }
    }
}
