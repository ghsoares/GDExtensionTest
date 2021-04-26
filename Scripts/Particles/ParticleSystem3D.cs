using System;
using System.Collections.Generic;
using Godot;

namespace ParticleSystem
{
    [Tool]
    public class ParticleSystem3D : MeshInstance
    {
        public enum UpdateMode
        {
            Process,
            PhysicsProcess
        }

        private Particle[] _particles;
        private Mesh _particleMesh;
        private AABB _particleMeshAABB;
        private AABB _multimeshAABB;

        protected RigidBody rigidbody { get; private set; }
        protected float drawTime { get; set; }

        public Particle[] particles
        {
            get
            {
                if (ResetParticles())
                {
                    _particles = new Particle[amount];
                    for (int i = 0; i < amount; i++)
                    {
                        Particle p = new Particle();
                        p.idx = i;
                        p.customData = new Dictionary<string, object>();
                        _particles[i] = p;
                    }
                    aliveParticles = 0;
                }
                return _particles;
            }
        }
        public RID multimesh { get; private set; }
        public RID baseRender { get; private set; }
        public PhysicsDirectSpaceState spaceState { get; private set; }
        public Transform prevTransform { get; private set; }
        public Vector3 currentVelocity { get; set; }
        public Vector3 externalForces { get; set; }
        public float currentVelocityLength { get; set; }
        public int aliveParticles { get; private set; }

        [Export] public bool emitting { get; set; }
        [Export] public int amount { get; set; }
        [Export]
        public Mesh particleMesh
        {
            get
            {
                return _particleMesh;
            }
            set
            {
                if (_particleMesh != value)
                {
                    _particleMesh = value;
                    if (_particleMesh == null)
                    {
                        VisualServer.MultimeshSetMesh(multimesh, new RID(null));
                    }
                    else
                    {
                        VisualServer.MultimeshSetMesh(multimesh, _particleMesh.GetRid());
                        _particleMeshAABB = _particleMesh.GetAabb();
                    }
                }
            }
        }
        [Export] public float timeScale { get; set; }
        [Export] public UpdateMode updateMode { get; set; }
        [Export] public Vector3 gravity { get; set; }
        [Export] public float lifetime { get; set; }
        [Export] public Vector3 size { get; set; }
        [Export] public Vector3 rotation { get; set; }
        [Export] public bool local { get; set; }
        [Export] public float fixedFPS { get; set; }
        [Export] public Curve sizeOverLifeCurve { get; set; }
        [Export] public Gradient colorOverLifeGradient { get; set; }
        [Export] public bool followDirection { get; set; }

        public ParticleSystem3D()
        {
            multimesh = VisualServer.MultimeshCreate();
            VisualServer.MultimeshSetVisibleInstances(multimesh, 0);
            SetBase(multimesh);

            emitting = true;
            fixedFPS = 0f;
            timeScale = 1f;
            updateMode = UpdateMode.PhysicsProcess;
            gravity = Vector3.Down * 9.8f;
            lifetime = 1f;
            size = Vector3.One;
            rotation = Vector3.Zero;
        }

        private bool ResetParticles()
        {
            if (_particles == null || _particles.Length != amount) return true;
            return false;
        }

        protected virtual void OnParticlesReseted() { }

        public override void _Process(float delta)
        {
            if (updateMode == UpdateMode.Process)
            {
                UpdateProcess(delta);
            }

            if (!OS.IsWindowFocused()) return;

            bool draw = true;

            if (fixedFPS > 0f)
            {
                draw = false;
                drawTime += delta * fixedFPS;
                while (drawTime >= 1f)
                {
                    draw = true;
                    drawTime -= 1f;
                }
            }

            if (draw)
            {
                DrawParticles();
            }
        }

        public override void _PhysicsProcess(float delta)
        {
            if (updateMode == UpdateMode.PhysicsProcess)
            {
                UpdateProcess(delta);
            }
        }

        private void UpdateMultimesh()
        {
            if (multimesh != null && VisualServer.MultimeshGetInstanceCount(multimesh) != amount)
            {
                VisualServer.MultimeshAllocate(
                    multimesh, amount, VisualServer.MultimeshTransformFormat.Transform3d,
                    VisualServer.MultimeshColorFormat.Float,
                    VisualServer.MultimeshCustomDataFormat.Float
                );
            }
        }

        private void UpdateProcess(float delta) {
            UpdateMultimesh();
            PreUpdateSystem(delta * timeScale);
            UpdateSystem(delta * timeScale);
            PosUpdateSystem(delta * timeScale);
        }

        protected virtual void PreUpdateSystem(float delta)
        {
            if (rigidbody != null)
            {
                currentVelocity = rigidbody.LinearVelocity;
            }
            else
            {
                currentVelocity = (GlobalTransform.origin - prevTransform.origin) / delta;
            }
            currentVelocityLength = currentVelocity.Length();

            spaceState = GetWorld().DirectSpaceState;
        }

        protected virtual void UpdateSystem(float delta)
        {
            for (int i = 0; i < amount; i++)
            {
                Particle particle = particles[i];
                if (particle.alive)
                {
                    UpdateParticle(particle, delta);
                    if (particle.life <= 0f || !particle.alive)
                    {
                        DestroyParticle(particle);
                        particle.alive = false;
                        particle.life = 0f;
                    }
                }
            }

            if (emitting)
            {
                EmissionProcess(delta);
            }
        }

        protected virtual void PosUpdateSystem(float delta)
        {
            externalForces = Vector3.Zero;
            prevTransform = GlobalTransform;
        }

        protected virtual void EmissionProcess(float delta) { }

        public virtual void EmitParticle(bool update = true)
        {
            for (int i = 0; i < amount; i++)
            {
                Particle particle = particles[i];
                if (!particle.alive)
                {
                    InitParticle(particle);
                    particle.lifetime = particle.life;
                    particle.startPosition = particle.position;
                    particle.startScale = particle.scale;
                    particle.startRotation = particle.rotation;
                    particle.startColor = particle.color;
                    if (update)
                    {
                        UpdateParticle(particle, 0f);
                    }
                    break;
                }
            }
        }

        protected virtual void InitParticle(Particle particle)
        {
            particle.customData.Clear();
            particle.custom = Colors.White;

            particle.alive = true;
            particle.life = lifetime;
            particle.persistent = false;

            particle.gravityScale = 1f;

            if (local)
            {
                particle.position = Vector3.Zero;
            }
            else
            {
                particle.position = GlobalTransform.origin;
            }
            particle.scale = size;
            particle.rotation = new Quat(rotation * Mathf.Deg2Rad(1f));

            particle.velocity = Vector3.Zero;

            particle.color = Colors.White;
            aliveParticles++;
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
            if (sizeOverLifeCurve != null)
            {
                particle.scale = particle.startScale * sizeOverLifeCurve.Interpolate(1f - lifeT);
            }
            if (colorOverLifeGradient != null)
            {
                particle.color = particle.startColor * colorOverLifeGradient.Interpolate(1f - lifeT);
            }

            if (followDirection)
            {
                Transform t = particle.transform;
                t = t.LookingAt(particle.position + particle.velocity, Vector3.Up);
                Basis b = t.basis;

                particle.rotation = b.RotationQuat();
                //particle.scale = b.Scale;
            }
        }

        protected virtual void DestroyParticle(Particle particle)
        {
            aliveParticles--;
        }

        protected virtual void DrawParticles()
        {
            int drawedParticles = 0;
            Transform invMat = Transform.Identity;
            if (!local)
            {
                invMat = GlobalTransform.AffineInverse();
            }
            for (int i = 0; i < amount; i++)
            {
                Particle p = particles[i];
                if (!p.alive) continue;

                Transform t = invMat * p.transform;

                VisualServer.MultimeshInstanceSetTransform(
                    multimesh, drawedParticles, t
                );
                VisualServer.MultimeshInstanceSetColor(
                    multimesh, drawedParticles, p.color
                );
                VisualServer.MultimeshInstanceSetCustomData(
                    multimesh, drawedParticles, p.custom
                );

                drawedParticles++;
            }
            VisualServer.MultimeshSetVisibleInstances(multimesh, drawedParticles);
            _multimeshAABB = VisualServer.MultimeshGetAabb(multimesh);
        }
    }
}
