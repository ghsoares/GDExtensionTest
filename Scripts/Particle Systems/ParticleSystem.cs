using System;
using System.Collections.Generic;
using ExtensionMethods.DictionaryExtensions;
using Godot;

public class ParticleSystem : Node2D
{
    public enum UpdateMode
    {
        Process,
        PhysicsProcess
    }

    protected RigidBody2D rigidbody { get; private set; }

    public Particle[] particles { get; private set; }
    public MultiMesh multimesh { get; private set; }
    public int aliveParticles { get; private set; }
    public Vector2 prevPos { get; private set; }
    public Vector2 currentVelocity { get; private set; }
    public Vector2 externalForces { get; private set; }
    public Physics2DDirectSpaceState spaceState { get; private set; }

    public float velocityMultiply = 1f;

    [Export] public bool emitting = true;
    [Export] public bool local = false;
    [Export] public int numParticles = 1024;
    [Export] public float lifetime = 1f;
    [Export] public Color color = Colors.White;
    [Export] public Vector2 gravity = Vector2.Down * 98f;
    [Export] public float timeScale = 1f;
    [Export] public UpdateMode updateMode = UpdateMode.PhysicsProcess;
    [Export] public Mesh mesh;
    [Export] public Texture texture;
    [Export] public Curve sizeOverLife;
    [Export] public Gradient colorOverLife;

    public virtual void ResetMultimesh()
    {
        if (mesh == null)
        {
            multimesh = null;
            return;
        }

        multimesh = new MultiMesh();
        multimesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform2d;
        multimesh.ColorFormat = MultiMesh.ColorFormatEnum.Float;
        multimesh.CustomDataFormat = MultiMesh.CustomDataFormatEnum.Float;
        multimesh.Mesh = mesh;
        multimesh.InstanceCount = numParticles;
    }

    public virtual void ResetParticles()
    {
        aliveParticles = 0;
        particles = new Particle[numParticles];

        for (int i = 0; i < numParticles; i++)
        {
            Particle part = new Particle();
            part.customData = new Dictionary<string, object>();
            part.idx = i;
            particles[i] = part;
        }
    }

    public virtual void ResetIfNeeded()
    {
        if (particles == null || particles.Length != numParticles)
        {
            ResetParticles();
        }

        if (multimesh == null || multimesh.InstanceCount != numParticles || multimesh.Mesh != mesh)
        {
            ResetMultimesh();
        }
    }

    public override void _Ready()
    {
        Node parent = GetParent();
        while (parent != null && !(parent is RigidBody2D))
        {
            parent = parent.GetParent();
        }
        if (parent != null)
        {
            rigidbody = parent as RigidBody2D;
        }

        ResetParticles();
        ResetMultimesh();
    }

    public void AddForce(Vector2 force)
    {
        externalForces += force;
    }

    public override void _PhysicsProcess(float delta)
    {
        if (updateMode == UpdateMode.PhysicsProcess)
        {
            ResetIfNeeded();
            UpdateSystem(delta * Mathf.Max(timeScale, 0f));
        }
    }

    public override void _Process(float delta)
    {
        if (updateMode == UpdateMode.PhysicsProcess)
        {
            ResetIfNeeded();
            UpdateSystem(delta * Mathf.Max(timeScale, 0f));
        }
        Update();
    }

    public virtual void Emit() {}

    public virtual void EmitParticle(Dictionary<string, object> overrideParams = null, bool update = true)
    {
        if (overrideParams == null) overrideParams = new Dictionary<string, object>();
        for (int i = 0; i < numParticles; i++)
        {
            Particle particle = particles[i];
            if (!particle.alive)
            {
                aliveParticles += 1;
                InitParticle(particle, overrideParams);
                particle.lifetime = particle.life;
                particle.startSize = particle.size;
                particle.startColor = particle.color;
                if (update)
                {
                    UpdateParticle(particle, 0f);
                }
                break;
            }
        }
    }

    protected virtual void UpdateSystem(float delta)
    {
        if (rigidbody != null)
        {
            currentVelocity = rigidbody.LinearVelocity;
        }
        else
        {
            currentVelocity = (GlobalPosition - prevPos) / delta;
        }

        spaceState = GetWorld2d().DirectSpaceState;

        for (int i = 0; i < numParticles; i++)
        {
            Particle particle = particles[i];
            if (particle.alive)
            {
                UpdateParticle(particle, delta);
                if (particle.life <= 0f || !particle.alive)
                {
                    DestroyParticle(particle);
                    aliveParticles -= 1;
                    particle.alive = false;
                    particle.life = 0f;
                }
            }
        }

        prevPos = GlobalPosition;
        externalForces = Vector2.Zero;

        if (emitting) {
            EmissionProcess(delta);
        }
    }

    protected virtual void EmissionProcess(float delta) {}

    protected virtual void InitParticle(Particle particle, Dictionary<String, object> overrideParams)
    {
        particle.customData.Clear();
        particle.customDataVertex = Colors.White;

        particle.alive = true;
        particle.life = (float)overrideParams.Get("lifetime", lifetime);
        particle.persistent = false;

        particle.gravityScale = (float)overrideParams.Get("gravityScale", lifetime);

        if (local)
        {
            particle.position = (Vector2)overrideParams.Get("position", Vector2.Zero);
        }
        else
        {
            particle.position = (Vector2)overrideParams.Get("position", GlobalPosition);
        }

        particle.size = (Vector2)overrideParams.Get("size", Vector2.One);
        particle.rotation = (float)overrideParams.Get("rotation", 0f);

        particle.velocity = (Vector2)overrideParams.Get("velocity", Vector2.Zero);

        particle.color = (Color)overrideParams.Get("color", color);
    }

    protected virtual void UpdateParticle(Particle particle, float delta)
    {
        particle.position += particle.velocity * delta;
        particle.velocity += externalForces * delta;
        particle.velocity += gravity * delta * particle.gravityScale;
        if (!particle.persistent)
        {
            particle.life -= delta;
            particle.life = Mathf.Clamp(particle.life, 0f, particle.lifetime);
        }
        float lifeT = particle.life / particle.lifetime;
        if (sizeOverLife != null)
        {
            particle.size = particle.startSize * sizeOverLife.Interpolate(lifeT);
        }
        if (colorOverLife != null)
        {
            particle.color = particle.startColor * colorOverLife.Interpolate(lifeT);
        }

        Color dataColor = particle.customDataVertex;

        dataColor.r = particle.position.x;
        dataColor.g = particle.position.y;

        particle.customDataVertex = dataColor;
    }

    protected virtual void DestroyParticle(Particle particle) { }

    public override void _Draw()
    {
        if (Visible)
        {
            DrawCircle(Vector2.Zero, 0f, Colors.White);
            if (!local) DrawSetTransformMatrix(GlobalTransform.AffineInverse());
            DrawParticles();
        }
    }

    protected virtual void DrawParticles()
    {
        if (multimesh != null)
        {
            int visibleParticles = 0;
            foreach (Particle particle in particles)
            {
                if (particle.alive)
                {
                    Transform2D t = particle.transform;

                    t.y = -t.y;

                    multimesh.SetInstanceTransform2d(visibleParticles, t);
                    multimesh.SetInstanceColor(visibleParticles, particle.color);
                    multimesh.SetInstanceCustomData(visibleParticles, particle.customDataVertex);
                    visibleParticles++;
                }
            }

            multimesh.VisibleInstanceCount = visibleParticles;

            DrawMultimesh(multimesh, texture);
        }
    }
}
