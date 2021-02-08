using Godot;

[Tool]
public class ParticleSystemEmitDistance : ParticleSystemModule {
    private Vector2 prevPos {get; set;}

    [Export]
    public float rate = 8f;

    public override void InitModule() {
        prevPos = particleSystem.pos;
    }

    public override void UpdateModule(float delta) {
        Vector2 curr = particleSystem.pos;
        Vector2 deltaPos = curr - prevPos;
        float dist = deltaPos.Length();
        float deltaS = 1f / rate;

        if (dist >= deltaS) {
            if (particleSystem.emitting) {
                for (float s = deltaS; s <= dist; s += deltaS) {
                    float t = s / dist;
                    Vector2 pos = prevPos.LinearInterpolate(curr, t);
                    particleSystem.Emit(new ParticleSystem2D.EmitParams {
                        position = pos
                    });
                }
            }
            prevPos = curr;
        }
    }
}