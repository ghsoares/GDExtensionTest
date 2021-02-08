using Godot;

[Tool]
public class ParticleSystemEmitRate : ParticleSystemModule {
    private float currentRate {get; set;}

    [Export]
    public float rate = 8f;

    public override void UpdateModule(float delta) {
        if (!particleSystem.emitting) {
            currentRate = 0f;
            return;
        }
        currentRate += delta * rate;
        while (currentRate >= 1f) {
            particleSystem.Emit(1);
            currentRate -= 1f;
        }
    }
}