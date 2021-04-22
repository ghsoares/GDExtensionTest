using Godot;

public class Grass : Line2D {
    Transform2D playerTransform {get; set;}

    public float totalSize {get; private set;}

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
        int numPoints = Mathf.CeilToInt(planet.totalSize.x * resolution);

        ClearPoints();
        totalSize = 0f;
        Vector2 prevP = new Vector2(0f, terrain.GetTerrainY(0));

        for (int i = numPoints - 1; i >= 0; i--) {
            float x = i / resolution;
            x = Mathf.Min(x, planet.totalSize.x);
            float y = terrain.GetTerrainY(x);
            Vector2 p = new Vector2(x, y);
            AddPoint(p);
            
            float l = (p - prevP).Length();
            totalSize += l;
            prevP = p;
        }

        Width = height * 2f;
        DefaultColor = Colors.White;
        TextureMode = LineTextureMode.Stretch;

        if (mat != null) {
            mat.SetShaderParam("size", new Vector2(totalSize * sizeScale, height));
        }
    }

    public override void _PhysicsProcess(float delta)
    {
        if (mat != null) {
            mat.SetShaderParam("windSpeed", planet.windSpeed.x);
            
            Transform2D currentPlayerTransform = Player.instance.GlobalTransform;
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