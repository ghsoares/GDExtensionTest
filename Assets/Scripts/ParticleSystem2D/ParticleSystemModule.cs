using Godot;

[Tool]
public class ParticleSystemModule : Node {
    public enum DrawMode {
        Single,
        Batch
    }

    [Export]
    public bool enabled = true;

    public ParticleSystem2D particleSystem {get; set;}
    public Physics2DDirectSpaceState spaceState {get; set;}
    public DrawMode drawMode = DrawMode.Single;

    public virtual void InitModule() {}

    public virtual void EmitSimple() {}

    public virtual void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams) {}

    public virtual void UpdateModule(float delta) {}

    public virtual void UpdateParticle(ref ParticleSystem2D.Particle p, float delta) {}

    public virtual void DrawModule() {}

    public virtual void DrawParticle(ParticleSystem2D.Particle p) {}

    public virtual void DrawBatch(ParticleSystem2D.Particle[] particles) {}
}