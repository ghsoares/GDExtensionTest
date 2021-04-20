using System.Collections.Generic;
using ExtensionMethods.Transform2DMethods;
using Godot;

public class LiquidBody : Control
{
    public enum HazardType {
        None,
        Lava
    }

    public struct LiquidSurfacePoint {
        public int idx {get; set;}
        public Vector2 pos {get; set;}
        public Vector2 velocity {get; set;}
    }
    class SurfacePoint
    {
        public int idx { get; set; }
        public float posY { get; set; }
        public float velocityY { get; set; }
        public float force { get; set; }
    }

    private static List<LiquidBody> _activeBodies { get; set; }
    public static List<LiquidBody> activeBodies
    {
        get
        {
            if (_activeBodies == null)
            {
                _activeBodies = new List<LiquidBody>();
            }
            return _activeBodies;
        }
    }

    public float windOffset { get; set; }
    public bool cullSurfacePoints {get; set;}
    public HazardType hazardType = HazardType.None;

    VisibilityNotifier2D visibleNotifier {get; set;}
    SurfacePoint[] surfacePoints { get; set; }
    int numPoints { get; set; }
    float spacing { get; set; }

    [Export] public float desiredVertexSpacing = 8f;
    [Export] public float springConstant = 16f;
    [Export] public float dampening = .25f;
    [Export] public float spread = 1f;
    [Export] public float borderConstraintLength = 32f;
    [Export] public OpenSimplexNoise windNoise;
    [Export] public float windStrength = 0f;
    [Export] public float drag = .25f;

    public LiquidBody()
    {
        windNoise = new OpenSimplexNoise();
        windNoise.Octaves = 1;
        windNoise.Period = 20f;
        windNoise.Seed = new System.Random().Next();
    }

    public override void _Ready()
    {
        Name = "LiquidBody";

        visibleNotifier = new VisibilityNotifier2D();
        visibleNotifier.Rect = new Rect2(Vector2.Zero, RectSize);
        AddChild(visibleNotifier);

        Initialize();
    }

    public override void _EnterTree()
    {
        activeBodies.Add(this);
    }

    public override void _ExitTree()
    {
        activeBodies.Remove(this);
    }

    public void Initialize()
    {
        numPoints = Mathf.CeilToInt(RectSize.x / desiredVertexSpacing);
        if (numPoints <= 1)
        {
            QueueFree();
            GD.PushWarning("Liquid initialized with 1 or less vertices, this is not allowed.");
            return;
        }
        spacing = RectSize.x / numPoints;

        surfacePoints = new SurfacePoint[numPoints];

        for (int i = 0; i < numPoints; i++)
        {
            float t = i / (float)(numPoints - 1);
            Vector2 targetPos = new Vector2(t * RectSize.x, 0f);

            SurfacePoint p = new SurfacePoint();

            p.idx = i;

            if (i % 8 == 0 && i != numPoints - 1)
            {
                //p.posY += (GD.Randf() * 2f - 1f) * 8f;
                //p.pos += Vector2.Up * 64f;
            }

            surfacePoints[i] = p;
        }
    }

    private void UpdatePoints(float delta)
    {
        for (int i = 0; i < numPoints; i++)
        {
            SurfacePoint p = surfacePoints[i];

            p.velocityY += p.force * delta;
            p.force = 0f;

            float t = i / (float)(numPoints - 1);
            float targetOff = -p.posY;

            float acc = Mathf.Clamp(springConstant * delta, 0f, 1f) * targetOff;
            acc += -p.velocityY * Mathf.Clamp(dampening * delta, 0f, 1f);

            p.posY += p.velocityY * delta;
            p.velocityY += acc;
        }

        float[] leftDeltas = new float[numPoints];
        float[] rightDeltas = new float[numPoints];

        for (int j = 0; j < 8; j++)
        {
            for (int i = 0; i < numPoints; i++)
            {
                if (i > 0)
                {
                    leftDeltas[i] = spread * (surfacePoints[i].posY - surfacePoints[i - 1].posY);
                    surfacePoints[i - 1].velocityY += leftDeltas[i] * delta;
                }
                if (i < numPoints - 1)
                {
                    rightDeltas[i] = spread * (surfacePoints[i].posY - surfacePoints[i + 1].posY);
                    surfacePoints[i + 1].velocityY += rightDeltas[i] * delta;
                }
            }
            for (int i = 0; i < numPoints; i++)
            {
                if (i > 0)
                {
                    surfacePoints[i - 1].posY += leftDeltas[i] * delta;
                }
                if (i < numPoints - 1)
                {
                    surfacePoints[i + 1].posY += rightDeltas[i] * delta;
                }
            }
        }

        for (int i = 0; i < numPoints; i++)
        {
            SurfacePoint p = surfacePoints[i];
            float t = i / (float)(numPoints - 1);
            float x = t * RectSize.x;

            float borderDistance = x;
            borderDistance = Mathf.Min(borderDistance, RectSize.x - x);
            float borderT = 1f - Mathf.Clamp(borderDistance / borderConstraintLength, 0f, 1f);

            float w = windNoise.GetNoise1d(RectGlobalPosition.x + x + windOffset);
            p.posY += windStrength * w * delta;

            p.posY = Mathf.Lerp(p.posY, 0f, borderT);
        }
    }

    public List<LiquidSurfacePoint> GetSurfacePointsInBounds(Rect2 bounds)
    {
        List<LiquidSurfacePoint> points = new List<LiquidSurfacePoint>();

        if (numPoints == 0) return points;

        float localMin = bounds.Position.x - RectGlobalPosition.x;
        float localMax = bounds.End.x - RectGlobalPosition.x;
        int minIdx = Mathf.FloorToInt(localMin / spacing);
        int maxIdx = Mathf.CeilToInt(localMax / spacing);

        minIdx = Mathf.Clamp(minIdx, 0, numPoints - 1);
        maxIdx = Mathf.Clamp(maxIdx, 0, numPoints - 1);

        for (int i = minIdx; i <= maxIdx; i++)
        {
            SurfacePoint p = surfacePoints[i];
            float t = i / (float)(numPoints - 1);
            Vector2 pos = new Vector2(t * RectSize.x, p.posY);

            pos = GetGlobalTransform().Xform(pos);
            if (pos.x >= bounds.Position.x && pos.x <= bounds.End.x)
            {
                points.Add(new LiquidSurfacePoint {
                    idx = i,
                    pos = pos,
                    velocity = new Vector2(0f, p.velocityY)
                });
            }
        }

        return points;
    }

    public void ApplyForce(int surfaceIdx, float force)
    {
        if (surfaceIdx < 0 || surfaceIdx >= numPoints) return;
        surfacePoints[surfaceIdx].force += force;
    }

    public override void _PhysicsProcess(float delta)
    {
        if (numPoints == 0) return;
        UpdatePoints(delta);
    }

    public override void _Process(float delta)
    {
        if (numPoints == 0) return;
        ShaderMaterial mat = Material as ShaderMaterial;
        if (mat != null)
        {
            mat.SetShaderParam("bodySize", RectSize);
        }
        Visible = visibleNotifier.IsOnScreen();
        Update();
    }

    private void GetVisiblePoints(out int minIdx, out int maxIdx) {
        minIdx = 0;
        maxIdx = numPoints - 1;

        if (cullSurfacePoints) {
            Rect2 scRect = GetViewportRect();
            scRect = GetViewport().CanvasTransform.XformInv(scRect);

            float localMin = scRect.Position.x - RectGlobalPosition.x;
            float localMax = scRect.End.x - RectGlobalPosition.x;

            minIdx = Mathf.FloorToInt(localMin / spacing);
            maxIdx = Mathf.CeilToInt(localMax / spacing);

            minIdx -= 1;
            maxIdx += 1;

            minIdx = Mathf.Clamp(minIdx, 0, numPoints - 1);
            maxIdx = Mathf.Clamp(maxIdx, 0, numPoints - 1);
        }
    }

    public override void _Draw()
    {
        if (!Visible) return;

        GetVisiblePoints(out int minIdx, out int maxIdx);
        int numVisiblePoints = maxIdx - minIdx;
        numVisiblePoints++;

        if (numVisiblePoints <= 1) return;

        Vector2[] vertices = new Vector2[numVisiblePoints * 2];
        int[] triangles = new int[(numVisiblePoints - 1) * 6];
        Color[] colors = new Color[numVisiblePoints * 2];
        Vector2[] uvs = new Vector2[numVisiblePoints * 2];

        int vertIdx = 0;
        int triIdx = 0;

        for (int i = minIdx; i <= maxIdx; i++)
        {
            float t = i / (float)(numPoints - 1);
            Vector2 pos = new Vector2(t * RectSize.x, surfacePoints[i].posY);

            vertices[vertIdx + 0] = pos;
            vertices[vertIdx + 1] = new Vector2(pos.x, RectSize.y);
            uvs[vertIdx + 0] = new Vector2(t, 0f);
            uvs[vertIdx + 1] = new Vector2(t, 1f);
            colors[vertIdx + 0] = Colors.White;
            colors[vertIdx + 1] = Colors.White;

            if (i < maxIdx)
            {
                triangles[triIdx + 0] = vertIdx + 1;
                triangles[triIdx + 1] = vertIdx + 0;
                triangles[triIdx + 2] = vertIdx + 3;

                triangles[triIdx + 3] = vertIdx + 3;
                triangles[triIdx + 4] = vertIdx + 0;
                triangles[triIdx + 5] = vertIdx + 2;
            }

            vertIdx += 2;
            triIdx += 6;
        }

        //if (indices.Length > 0) DrawPolygon(polygonPoints, colors, uvs);
        VisualServer.CanvasItemAddTriangleArray(
            GetCanvasItem(), triangles, vertices, colors, uvs, null, null, new RID(null), -1, new RID(null)
        );
    }
}