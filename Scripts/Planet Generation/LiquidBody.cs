using Godot;

public class LiquidBody : Control {
    class SurfacePoint {
        public int idx {get; set;}
        public Vector2 pos {get; set;}
        public Vector2 velocity {get; set;}
    }

    SurfacePoint[] surfacePoints {get; set;}
    int numPoints {get; set;}
    float spacing {get; set;}
    Texture tex {get; set;}

    [Export] public float desiredVertexSpacing = 8f;
    [Export] public float springConstant = 16f;
    [Export] public float dampening = .5f;
    [Export] public float spread = .25f;
    [Export] public float borderConstraintLength = 16f;

    public override void _Ready()
    {
        Name = "LiquidBody";
        tex = ResourceLoader.Load<Texture>("res://icon.png");
        Initialize();
    }

    private void Initialize() {
        numPoints = Mathf.CeilToInt(RectSize.x / desiredVertexSpacing);
        if (numPoints <= 1) {
            QueueFree();
            GD.PushWarning("Liquid initialized with 1 or less vertices, this is not allowed.");
            return;
        }
        spacing = RectSize.x / numPoints;

        surfacePoints = new SurfacePoint[numPoints];

        for (int i = 0; i < numPoints; i++) {
            float t = i / (float)(numPoints - 1);
            Vector2 targetPos = new Vector2(t * RectSize.x, 0f);

            SurfacePoint p = new SurfacePoint();

            p.idx = i;
            p.pos = targetPos;

            if (i % 4 == 0) {
                p.pos += new Vector2(GD.Randf() * 2f - 1f, GD.Randf() * 2f - 1f) * 64f;
                //p.pos += Vector2.Up * 64f;
            }

            surfacePoints[i] = p;
        }
    }

    private void UpdatePoints(float delta) {
        for (int i = 0; i < numPoints; i++) {
            SurfacePoint p = surfacePoints[i];

            float t = i / (float)(numPoints - 1);
            Vector2 targetPos = new Vector2(t * RectSize.x, 0f);
            Vector2 targetOff = (targetPos - p.pos);

            Vector2 acc = Mathf.Clamp(springConstant * delta, 0f, 1f) * targetOff;
            acc += -p.velocity * Mathf.Clamp(dampening * delta, 0f, 1f);

            p.pos += p.velocity * delta;
            p.velocity += acc;
        }

        Vector2[] leftDeltas = new Vector2[numPoints];
        Vector2[] rightDeltas = new Vector2[numPoints];

        for (int j = 0; j < 8; j++) {
            for (int i = 0; i < numPoints; i++) {
                if (i > 0) {
                    leftDeltas[i] = spread * (surfacePoints[i].pos - surfacePoints[i - 1].pos);
                    surfacePoints[i - 1].velocity += leftDeltas[i] * delta;
                }
                if (i < numPoints - 1) {
                    rightDeltas[i] = spread * (surfacePoints[i].pos - surfacePoints[i + 1].pos);
                    surfacePoints[i + 1].velocity += rightDeltas[i] * delta;
                }
            }
            for (int i = 0; i < numPoints; i++) {
                if (i > 0) {
                    surfacePoints[i - 1].pos += leftDeltas[i] * delta;
                }
                if (i < numPoints - 1) {
                    surfacePoints[i + 1].pos += rightDeltas[i] * delta;
                }
            }
        }
        for (int i = 0; i < numPoints; i++) {
            SurfacePoint p = surfacePoints[i];
            Vector2 pos = p.pos;
            float t = i / (float)(numPoints - 1);
            Vector2 targetPos = new Vector2(t * RectSize.x, 0f);
            if (i > 0) {
                SurfacePoint prev = surfacePoints[i - 1];
                pos.x = Mathf.Max(pos.x, prev.pos.x);
            }
            if (i < numPoints - 1) {
                SurfacePoint nxt = surfacePoints[i + 1];
                pos.x = Mathf.Min(pos.x, nxt.pos.x);
            }
            float borderDistance = pos.x;
            borderDistance = Mathf.Min(borderDistance, RectSize.x - pos.x);
            float borderT = 1f - Mathf.Clamp(borderDistance / borderConstraintLength, 0f, 1f);
            pos = pos.LinearInterpolate(targetPos, borderT);
            p.pos = pos;
        }
    }

    public override void _PhysicsProcess(float delta)
    {
        UpdatePoints(delta * .2f);
    }

    public override void _Process(float delta)
    {
        Update();
    }

    public override void _Draw()
    {
        RID canvasItemRID = GetCanvasItem();

        Vector2[] polygonPoints = new Vector2[numPoints + 2];
        Color[] colors = new Color[numPoints + 2];
        Vector2[] uvs = new Vector2[numPoints + 2];

        for (int i = 0; i < numPoints; i++) {
            float t = i / (float)(numPoints - 1);
            Vector2 pos = surfacePoints[i].pos;
            polygonPoints[i] = pos;
            colors[i] = Colors.White;
            uvs[i] = new Vector2(t, 0f);
            pos.y = RectSize.y;
            /*int j = numPoints + ((numPoints - 1) - i);
            polygonPoints[j] = pos;
            colors[j] = Colors.White;*/
        }

        polygonPoints[numPoints+0] = RectSize;
        polygonPoints[numPoints+1] = new Vector2(0f, RectSize.y);
        colors[numPoints+0] = Colors.White;
        colors[numPoints+1] = Colors.White;
        uvs[numPoints+0] = new Vector2(1f, 1f);
        uvs[numPoints+1] = new Vector2(0f, 1f);

        int[] indices = Geometry.TriangulatePolygon(polygonPoints); // Invalid polygon don't throw error
        //if (indices.Length > 0) DrawPolygon(polygonPoints, colors, uvs);
        if (indices.Length > 0) {
            VisualServer.CanvasItemAddTriangleArray(
                GetCanvasItem(), indices, polygonPoints, colors, uvs, null, null, tex.GetRid(), -1, tex.GetRid()
            );
        }
    }
}