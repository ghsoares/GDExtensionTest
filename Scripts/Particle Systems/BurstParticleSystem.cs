using System.Collections.Generic;
using Godot;

public class BurstParticleSystem : ParticleSystem {
    [Export] public Vector2 amountRange = Vector2.One * 32f;

    public override void EmitParticle(Dictionary<string, object> overrideParams = null, bool update = true)
    {
        int amount = Mathf.FloorToInt((float)GD.RandRange(amountRange.x, amountRange.y + 1));
        for (int i = 0; i < amount; i++) {
            base.EmitParticle(overrideParams, update);
        }
    }
}