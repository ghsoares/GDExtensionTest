using Godot;

public class Grass : Line2D {
    private Transform2D playerTransform {get; set;}
    private Vector2[] points {get; set;}
    private float[] pointsOffset {get; set;}
    private int numPoints {get; set;}

    public ShaderMaterial mat;
    public Planet planet;
    public float sizeScale = 1f;
    public float height = 16f;
    public float resolution = 1f/4f;
    public float playerThrusterAngleTransitionLength = 32f;
    public Vector2 playerThrusterAngleRangeMin = new Vector2(15f, 30f);
    public Vector2 playerThrusterAngleRangeMax = new Vector2(45f, 90f);

    public void Create() {
        mat = Material as ShaderMaterial;
        Terrain terrain = planet.terrain;
        numPoints = Mathf.CeilToInt(planet.totalSize.x * resolution);

        points = new Vector2[numPoints];
        pointsOffset = new float[numPoints];

        float totalSize = 0f;
        Vector2 prevP = new Vector2(0f, terrain.GetTerrainY(0));

        for (int i = 0; i < numPoints; i++) {
            float x = i / resolution;
            float y = terrain.GetTerrainY(x);
            Vector2 p = new Vector2(x, y);
            
            float l = (p - prevP).Length();
            totalSize += l;
            prevP = p;

            points[i] = p;
            pointsOffset[i] = -totalSize;
        }

        Width = height * 2f;
        DefaultColor = Colors.White;
        TextureMode = LineTextureMode.Stretch;
    }

    public override void _Process(float delta)
    {
        UpdatePoints();
    }

    private void UpdatePoints() {
        Transform2D viewportTransform = GetViewport().CanvasTransform.AffineInverse();
        Vector2 size = GetViewport().Size;

        float minX = viewportTransform.origin.x;
        float maxX = viewportTransform.origin.x + size.x;

        int minIdx = Mathf.FloorToInt(minX * resolution);
        int maxIdx = Mathf.CeilToInt(maxX * resolution);

        minIdx = Mathf.Clamp(minIdx, 0, numPoints - 1);
        maxIdx = Mathf.Clamp(maxIdx, 0, numPoints - 1);

        ClearPoints();

        int n = 0;
        Vector2[] renderPoints = new Vector2[(maxIdx - minIdx) + 1];
        for (int i = minIdx; i <= maxIdx; i++) {
            renderPoints[n] = points[i];

            n++;
        }
        /*System.Console.WriteLine($"Number of grass points: {n}, min idx: {minIdx}, max idx: {maxIdx}");
        System.Console.WriteLine($"Min offset: {pointsOffset[minIdx]}, max offset: {pointsOffset[maxIdx]}");*/

        Points = renderPoints;

        float totalSize = Mathf.Abs(pointsOffset[minIdx] - pointsOffset[maxIdx]);

        if (mat != null) {
            mat.SetShaderParam("offset", pointsOffset[minIdx]);
            mat.SetShaderParam("size", new Vector2(totalSize, height));
        }
    }

    public override void _PhysicsProcess(float delta)
    {
        if (mat != null) {
            mat.SetShaderParam("windSpeed", planet.windSpeed.x);
            
            Transform2D currentPlayerTransform = Player.instance.transform;
            float heightDiff = planet.terrain.GetTerrainY(currentPlayerTransform.origin.x) - currentPlayerTransform.origin.y;
            heightDiff -= 16f;
            float t = 1f - Mathf.Clamp(heightDiff / playerThrusterAngleTransitionLength, 0f, 1f);
            Vector2 thrusterAngleRange = playerThrusterAngleRangeMin.LinearInterpolate(playerThrusterAngleRangeMax, t);
            currentPlayerTransform = GlobalTransform.AffineInverse() * currentPlayerTransform;

            playerTransform = playerTransform.InterpolateWith(currentPlayerTransform, Mathf.Clamp(4f * delta, 0f, 1f));

            mat.SetShaderParam("playerTransform", playerTransform);
            mat.SetShaderParam("playerThrusterAngleRange", thrusterAngleRange);

            State<Player> playerCurrentState = Player.instance.stateMachine.currentState;
            if (playerCurrentState is PlayerHoverState) {
                PlayerHoverState state = (PlayerHoverState)playerCurrentState;
                mat.SetShaderParam("playerThrusterPercentage", state.thrusterT);
            } else {
                mat.SetShaderParam("playerThrusterPercentage", 0f);
            }
        }
    }
}