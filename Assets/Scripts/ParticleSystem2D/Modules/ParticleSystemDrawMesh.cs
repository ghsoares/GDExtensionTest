using Godot;

[Tool]
public class ParticleSystemDrawMesh : ParticleSystemModule {
    private MultiMesh multimesh {get; set;}
    private Transform2D ZERO_TRANSFORM = Transform2D.Identity.Scaled(Vector2.Zero);

    [Export]
    public Texture tex;
    [Export]
    public Texture normalMap;
    [Export]
    public Mesh mesh;
    [Export]
    public Material material;

    public override void InitModule() {
        drawMode = DrawMode.Batch;
        Reset();
    }

    private void Reset() {
        Mesh usedMesh = mesh;

        if (usedMesh == null) {
            SurfaceTool st = new SurfaceTool();

            st.Begin(Mesh.PrimitiveType.Triangles);

            st.AddUv        (new Vector2(0, 1));
            st.AddVertex    (new Vector3(-1f, -1f, 0));
            st.AddUv        (new Vector2(1, 1));
            st.AddVertex    (new Vector3( 1f, -1f, 0));
            st.AddUv        (new Vector2(0, 0));
            st.AddVertex    (new Vector3(-1f, 1f, 0));

            st.AddUv        (new Vector2(1, 1));
            st.AddVertex    (new Vector3( 1f, -1f, 0));
            st.AddUv        (new Vector2(1, 0));
            st.AddVertex    (new Vector3( 1f,  1f, 0));
            st.AddUv        (new Vector2(0, 0));
            st.AddVertex    (new Vector3(-1f, 1f, 0));

            st.SetMaterial(material);
            st.Index();

            usedMesh = st.Commit();
        }

        multimesh = new MultiMesh();
        multimesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform2d;
        multimesh.ColorFormat = MultiMesh.ColorFormatEnum.Float;
        multimesh.CustomDataFormat = MultiMesh.CustomDataFormatEnum.Float;
        multimesh.Mesh = usedMesh;
        multimesh.InstanceCount = particleSystem.maxParticles;
    }

    private void InitMultiMeshIfNeeded() {
        if (multimesh == null || multimesh.InstanceCount != particleSystem.maxParticles) Reset();
    }

    public override void DrawBatch(ParticleSystem2D.Particle[] particles) {
        InitMultiMeshIfNeeded();
        
        foreach (ParticleSystem2D.Particle p in particles) {
            if (p.alive) {
                Transform2D t = new Transform2D();
                t.origin = p.position;

                t.x = Vector2.Right.Rotated(Mathf.Deg2Rad(p.rotation)) * p.size;
                t.y = Vector2.Up.Rotated(Mathf.Deg2Rad(p.rotation)) * p.size;

                multimesh.SetInstanceTransform2d(p.idx, t);
                multimesh.SetInstanceColor(p.idx, p.color);
                multimesh.SetInstanceCustomData(p.idx, p.customDataColor);
            } else {
                multimesh.SetInstanceTransform2d(p.idx, ZERO_TRANSFORM);
            }
        }

        particleSystem.DrawMultimesh(multimesh, tex, normalMap);
    }
}