using Godot;

public class ParticleSystem3DRenderer : Node2D {
    const float pixelSize = .01f;

    private MultiMesh multimesh {get; set;}
    public ParticleSystem parentSystem {get; private set;}
    public Viewport view {get; private set;}
    public Camera camera {get; private set;}
    private MultiMeshInstance multimeshInstance {get; set;}
    public TextureRect viewTexRect {get; private set;}
    public float cameraBaseSize {get; private set;}

    [Export] public float cameraOffset = 4f;
    [Export] public Mesh mesh;

    public void ResetMultiMesh() {
        multimesh = new MultiMesh();
        multimesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform3d;
        multimesh.ColorFormat = MultiMesh.ColorFormatEnum.Float;
        multimesh.CustomDataFormat = MultiMesh.CustomDataFormatEnum.Float;
        multimesh.Mesh = mesh;
        multimesh.InstanceCount = parentSystem.numParticles;
    }

    public void Reset() {
        parentSystem = GetParent() as ParticleSystem;
        Viewport baseView = GetViewport();

        ResetMultiMesh();

        if (view == null) {
            view = new Viewport();
            view.TransparentBg = true;
            view.Keep3dLinear = true;
            view.RenderTargetVFlip = true;
            AddChild(view);
        }
        if (camera == null) {
            camera = new Camera();
            view.AddChild(camera);
            camera.Current = true;
        }
        if (multimeshInstance == null) {
            multimeshInstance = new MultiMeshInstance();
            multimeshInstance.Multimesh = multimesh;
            view.AddChild(multimeshInstance);
        }
        if (viewTexRect == null) {
            Node pivot = new Node();

            viewTexRect = new TextureRect();
            AddChild(viewTexRect);
            viewTexRect.UseParentMaterial = true;

            ViewportTexture viewTex = view.GetTexture();
            viewTexRect.Texture = viewTex;
        }
        view.Size = baseView.Size;

        cameraBaseSize = Mathf.Min(view.Size.x, view.Size.y) * pixelSize;
        camera.Projection = Camera.ProjectionEnum.Orthogonal;
        camera.Size = cameraBaseSize;
        camera.Translation = new Vector3(0f, 0f, cameraOffset);
    }

    public override void _Ready()
    {
        Reset();
        if (parentSystem == null) {
            GD.PushError("This node must be a direct child of a particle system!");
            QueueFree();
        }
    }

    public override void _Process(float delta)
    {
        Viewport baseView = GetViewport();
        Transform2D viewportTransform = baseView.CanvasTransform.AffineInverse();
        Vector2 pos = viewportTransform.origin;
        float zoom = viewportTransform.x.x;

        camera.Translation = new Vector3((pos.x + view.Size.x * .5f) * pixelSize, -(pos.y + view.Size.y * .5f) * pixelSize, cameraOffset);
        camera.Size = cameraBaseSize * zoom;
        multimeshInstance.Translation = new Vector3(GlobalPosition.x, -GlobalPosition.y, 0f) * pixelSize;

        viewTexRect.RectGlobalPosition = pos;
        viewTexRect.RectRotation = -GlobalRotationDegrees;

        UpdateMultiMesh();
    }

    private void UpdateMultiMesh() {
        if (multimesh != null)
        {
            Vector3 offset = -multimeshInstance.Translation;
            int visibleParticles = 0;
            foreach (Particle particle in parentSystem.particles)
            {
                if (particle.alive)
                {
                    Transform2D t = particle.transform;

                    Transform t3D = Godot.Transform.Identity;
                    Basis basis = Basis.Identity;

                    float size = t.x.x;

                    t3D.origin = new Vector3(t.origin.x, -t.origin.y, 0f) * pixelSize + offset;
                    basis.x = new Vector3(t.x.x, t.x.y, 0f) * pixelSize;
                    basis.y = new Vector3(t.y.x, t.y.y, 0f) * pixelSize;
                    basis.z *= size * pixelSize;
                    t3D.basis = basis;

                    multimesh.SetInstanceTransform(visibleParticles, t3D);
                    multimesh.SetInstanceColor(visibleParticles, particle.color);
                    multimesh.SetInstanceCustomData(visibleParticles, particle.customDataVertex);
                    visibleParticles++;
                }
            }

            multimesh.VisibleInstanceCount = visibleParticles;
        }
    }
}