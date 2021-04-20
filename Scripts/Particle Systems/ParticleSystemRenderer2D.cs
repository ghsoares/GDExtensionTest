using System;
using System.Diagnostics;
using Godot;

public class ParticleSystemRenderer2D : Node2D
{
    private MultiMesh multimesh { get; set; }
    private MultiMeshInstance2D multimeshInstance { get; set; }
    public ParticleSystem parentSystem { get; private set; }
    public Viewport view { get; private set; }
    public Camera2D camera { get; private set; }
    public TextureRect viewTexRect { get; private set; }

    [Export] public Mesh mesh;
    [Export] public ShaderMaterial meshMaterial;
    [Export] public Rect2 bounds = new Rect2();
    [Export] public Viewport.UsageEnum viewportUsage = Viewport.UsageEnum.Usage3dNoEffects;

    public void ResetMultiMesh()
    {
        multimesh = new MultiMesh();
        multimesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform2d;
        multimesh.ColorFormat = MultiMesh.ColorFormatEnum.Float;
        multimesh.CustomDataFormat = MultiMesh.CustomDataFormatEnum.Float;
        multimesh.Mesh = mesh;
        multimesh.InstanceCount = parentSystem.numParticles;
    }

    public void Reset()
    {
        parentSystem = GetParent() as ParticleSystem;
        Viewport baseView = GetViewport();

        ResetMultiMesh();

        if (view == null)
        {
            view = new Viewport();
            view.TransparentBg = true;
            view.Usage = viewportUsage;
            view.RenderTargetVFlip = true;
            AddChild(view);

            if (bounds.Size != Vector2.Zero)
            {
                view.Size = bounds.Size;
            }
            else
            {
                view.Size = baseView.Size;
            }
        }
        if (camera == null)
        {
            camera = new Camera2D();
            view.AddChild(camera);
            camera.Current = true;
            camera.ProcessMode = Camera2D.Camera2DProcessMode.Physics;
        }
        if (multimeshInstance == null)
        {
            multimeshInstance = new MultiMeshInstance2D();
            multimeshInstance.Multimesh = multimesh;
            multimeshInstance.Material = meshMaterial;
            view.AddChild(multimeshInstance);
        }
        if (viewTexRect == null)
        {
            Node pivot = new Node();

            viewTexRect = new TextureRect();
            viewTexRect.UseParentMaterial = true;
            AddChild(viewTexRect);

            ViewportTexture viewTex = view.GetTexture();
            viewTexRect.Texture = viewTex;
        }
    }

    public override void _Ready()
    {
        if (Visible)
        {
            Reset();
        }
        if (parentSystem == null)
        {
            GD.PushError("This node must be a direct child of a particle system!");
            QueueFree();
        }
    }

    public override void _PhysicsProcess(float delta)
    {
        if (parentSystem == null) return;

        Stopwatch stopWatch = new Stopwatch();
        stopWatch.Start();
        
        Viewport baseView = GetViewport();
        Transform2D cameraTransform = GameCamera.instance.GlobalTransform;

        viewTexRect.RectGlobalPosition = cameraTransform.origin - baseView.Size / 2f;
        viewTexRect.RectSize = baseView.Size;
        viewTexRect.RectRotation = -GlobalRotationDegrees;

        if (bounds.Size != Vector2.Zero)
        {
            viewTexRect.RectGlobalPosition = cameraTransform.Xform(bounds.Position);
            viewTexRect.RectSize = cameraTransform.BasisXform(bounds.Size);
        }

        camera.Position = viewTexRect.RectGlobalPosition + viewTexRect.RectSize * .5f;
        multimeshInstance.Position = camera.Position;

        ShaderMaterial mat = Material as ShaderMaterial;

        if (mat != null)
        {
            mat.SetShaderParam("globalTransform", viewTexRect.GetGlobalTransform());
        }

        UpdateMultiMesh();

        stopWatch.Stop();
        TimeSpan ts = stopWatch.Elapsed;

        string name = GetParent().Name + " 2D Renderer";

        /*Debug.instance.AddOutput(
            name + " Physics Process Time", name + " Physics Process Time: " + ts.Milliseconds + " ms"
        );*/
    }

    private void UpdateMultiMesh()
    {
        if (multimesh != null)
        {
            Vector2 offset = -multimeshInstance.Position;
            int visibleParticles = 0;
            foreach (Particle particle in parentSystem.particles)
            {
                if (particle.alive)
                {
                    Transform2D t = particle.transform;
                    t.y = -t.y;
                    t.origin += offset;

                    multimesh.SetInstanceTransform2d(visibleParticles, t);
                    multimesh.SetInstanceColor(visibleParticles, particle.color);
                    multimesh.SetInstanceCustomData(visibleParticles, particle.customDataVertex);
                    visibleParticles++;
                }
            }

            multimesh.VisibleInstanceCount = visibleParticles;
        }
    }
}
