using Godot;

[Tool]
public class ParticleSystemEmitBurst : ParticleSystemModule {
    private float currentRate {get; set;}

    [Export]
    public float rate = 8f;
    [Export]
    public int minAmount = 8, maxAmount = 8;

    public override void EmitSimple() {
        int amount = particleSystem.random.Next(minAmount, maxAmount+1);
        particleSystem.Emit(amount);
    }

    public override void UpdateModule(float delta) {
        if (!particleSystem.emitting) {
            currentRate = 0f;
            return;
        }
        currentRate += delta * rate;
        while (currentRate >= 1f) {
            int amount = particleSystem.random.Next(minAmount, maxAmount+1);
            particleSystem.Emit(amount);
            currentRate -= currentRate;
        }
    }
}