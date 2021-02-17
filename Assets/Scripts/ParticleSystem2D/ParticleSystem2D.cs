using Godot;
using System;
using System.Collections.Generic;
using ExtensionMethods.NodeMethods;
using System.Linq;

[Tool]
public class ParticleSystem2D : Node2D
{
    public struct Particle {
        public int idx {get; set;}

        public Vector2 prevPosition {get; set;}
        public Vector2 position {get; set;}
        public Vector2 velocity {get; set;}
        public float lifetime {get; set;}
        public float currentLife {get; set;}
        public bool alive {get; set;}

        public Color baseColor {get; set;}
        public Color color {get; set;}

        public Dictionary<string, System.Object> customData;
        public Color customDataColor {get; set;}

        public float baseSize {get; set;}
        public float size {get; set;}
        public float rotation {get; set;}

        public Rect2 drawRect {
            get {
                Rect2 r = new Rect2();
                r.Position = position - Vector2.One * size;
                r.Size = Vector2.One * size * 2f;
                return r;
            }
        }
        public float life {
            get {
                return Mathf.Clamp(currentLife / lifetime, 0, 1);
            }
        }
    }

    public class EmitParams {
        public Vector2 position = Vector2.Zero;
        public Vector2 shapeDirection = Vector2.Right;
    }

    public enum UpdateMode {
        Process,
        PhysicsProcess
    }

    public enum SpaceMode {
        World,
        Local
    }

    private Particle[] particles {get; set;}
    private ParticleSystemModule[] modules {get; set;}
    private float currentFrameDelta {get; set;}
    private Vector2 prevPos {get; set;}
    public Vector2 currentVelocity {get; set;}
    public Vector2 pos {
        get {
            switch (spaceMode) {
                case SpaceMode.Local: {
                    return Vector2.Zero;
                }
                case SpaceMode.World: {
                    return GlobalPosition;
                }
            }
            return Vector2.Zero;
        }
    }
    public float rot {
        get {
            switch (spaceMode) {
                case SpaceMode.Local: {
                    return 0f;
                }
                case SpaceMode.World: {
                    return GlobalRotation;
                }
            }
            return 0f;
        }
    }

    [Export]
    public UpdateMode updateMode = UpdateMode.PhysicsProcess;
    [Export]
    public SpaceMode spaceMode = SpaceMode.World;
    [Export]
    public int maxParticles = 256;
    [Export]
    public int seed = 1337;
    [Export]
    public bool emitting;
    [Export]
    public bool emitOnStart = true;
    [Export]
    public Vector2 gravity = Vector2.Down * 9.8f;
    [Export]
    public float onEditorSafeFPS = 10f;
    [Export(PropertyHint.Range, "0,60")]
    public int onEditorDrawFps = 24;
    [Export]
    public float timeScale = 1f;
    [Export]
    public bool debugMode = false;

    public override void _Ready() {
        Reset();
        if (!Engine.EditorHint) emitting = emitOnStart;
    }

    public void Reset() {
        prevPos = GlobalPosition;
        modules = this.GetChildren<ParticleSystemModule>(true).ToArray();

        particles = new Particle[maxParticles];

        for (int i = 0; i < maxParticles; i++) {
            particles[i] = new Particle {idx = i};
        }

        foreach (ParticleSystemModule module in modules) {
            module.particleSystem = this;
            module.InitModule();
        }
    }

    public T GetModule<T>() where T : ParticleSystemModule {
        return modules.OfType<T>().FirstOrDefault();
    }

    public void ResetIfNeeded() {
        bool resetParticles = particles == null || maxParticles != particles.Length;
        bool resetModules = modules == null || this.GetChildCount<ParticleSystemModule>() != modules.Length;
        if (resetParticles || (Engine.EditorHint && resetModules)) {
            Reset();
        }
    }

    public override void _Process(float delta) {
        delta = Mathf.Abs(delta);

        if (updateMode == UpdateMode.Process) {
            UpdateSystem(delta);
        }

        if (Engine.EditorHint) {
            float currFps = 1f / delta;
            if (currFps <= onEditorSafeFPS) {
                emitting = false;
            }

            currentFrameDelta += onEditorDrawFps * delta;
            if (currentFrameDelta >= 1f) {
                Update();
                currentFrameDelta -= Mathf.Floor(currentFrameDelta);
            }
        } else {
            Update();
        }
    }

    public override void _PhysicsProcess(float delta) {
        delta = Mathf.Abs(delta);

        if (updateMode == UpdateMode.PhysicsProcess) {
            UpdateSystem(delta);
        }
    }

    private void UpdateSystem(float delta) {
        try {
            if (timeScale < 0f) timeScale = 0f;
            delta *= timeScale;
            Vector2 deltaPos = GlobalPosition - prevPos;
            currentVelocity = deltaPos / delta;
            ResetIfNeeded();

            World2D world = GetWorld2d();
            RID spaceRID = world.Space;
            Physics2DDirectSpaceState spaceState = world.DirectSpaceState;

            foreach (ParticleSystemModule module in modules) {
                if (!module.enabled) continue;
                module.particleSystem = this;
                module.world = world;
                module.space = spaceRID;
                module.spaceState = spaceState;
                module.UpdateModule(delta);
                for (int i = 0; i < maxParticles; i++) {
                    if (particles[i].alive) {
                        module.UpdateParticle(ref particles[i], delta);
                        if (particles[i].currentLife <= 0f) {
                            particles[i].currentLife = 0f;

                            foreach (ParticleSystemModule module2 in modules) {
                                module2.DestroyParticle(ref particles[i]);
                            }

                            particles[i].alive = false;
                        }
                    }
                }
            }

            for (int i = 0; i < maxParticles; i++) {
                if (particles[i].alive) {
                    particles[i].prevPosition = particles[i].position;
                }
            }
            prevPos = GlobalPosition;
        } catch (Exception e) {
            if (Engine.EditorHint) emitting = false;
            GD.PrintErr(e);
        }
    }

    private void InternalEmit(int pIdx, EmitParams emitParams) {
        Particle p = particles[pIdx];

        p.customData = new Dictionary<string, object>();
        p.alive = true;

        World2D world = GetWorld2d();
        RID spaceRID = world.Space;
        Physics2DDirectSpaceState spaceState = world.DirectSpaceState;

        foreach (ParticleSystemModule module in modules) {
            if (!module.enabled) continue;

            module.world = world;
            module.space = spaceRID;
            module.spaceState = spaceState;

            module.InitParticle(ref p, emitParams);
        }

        p.prevPosition = p.position;

        particles[pIdx] = p;
    }

    public void Emit() {
        foreach (ParticleSystemModule module in modules) {
            if (!module.enabled) continue;
            module.EmitSimple();
        }
    }

    public void Emit(int amount) {
        EmitParams emitParams = new EmitParams {
            position = pos
        };
        Emit(emitParams, amount);
    }

    public void Emit(EmitParams emitParams, int amount = 1) {
        if (amount <= 0) return;
        for (int i = 0; i < maxParticles; i++) {
            if (!particles[i].alive) {
                InternalEmit(i, emitParams);
                amount--;
                if (amount == 0) break;
            }
        }
    }

    public EmitParams TransformFromGlobalSpace(EmitParams emitParams) {
        if (spaceMode == SpaceMode.Local) {
            emitParams.position = ToLocal(emitParams.position);
        }
        return emitParams;
    }

    public override void _Draw() {
        if (particles == null) return;

        try {
            if (spaceMode == SpaceMode.World) DrawSetTransformMatrix(GetGlobalTransform().AffineInverse()); // FIXME, move this to _process, to enable global drawing
            DrawRect(new Rect2(Vector2.Zero, Vector2.Zero), Colors.White);

            foreach (ParticleSystemModule module in modules) {
                if (!module.enabled) continue;

                module.DrawModule();

                switch (module.drawMode) {
                    case ParticleSystemModule.DrawMode.Single: {
                        foreach (Particle p in particles) {
                            if (p.alive) {
                                module.DrawParticle(p);
                            }
                        }
                        break;
                    }
                    case ParticleSystemModule.DrawMode.Batch: {
                        module.DrawBatch(particles);
                        break;
                    }
                }
            }
        } catch (Exception e) {
            if (Engine.EditorHint) emitting = false;
            throw e;
        }
    }
}
