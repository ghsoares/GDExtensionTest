using Godot;

public class Grass : Line2D {
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
        int numPoints = Mathf.CeilToInt(planet.size.x * resolution);

        ClearPoints();

        for (int i = numPoints - 1; i >= 0; i--) {
            float x = i / resolution;
            x = Mathf.Min(x, planet.size.x);
            float y = terrain.GetTerrainY(x);
            AddPoint(new Vector2(x, y));
        }

        Width = height * 2f;
        DefaultColor = Colors.White;
        TextureMode = LineTextureMode.Stretch;

        if (mat != null) {
            mat.SetShaderParam("size", new Vector2(planet.size.x * sizeScale, height));
        }
    }

    public override void _Process(float delta)
    {
        if (mat != null) {
            if (!Player.instance.dead) {
                Transform2D playerTransform = Player.instance.GlobalTransform;
                float heightDiff = planet.terrain.GetTerrainY(playerTransform.origin.x) - playerTransform.origin.y;
                heightDiff -= 16f;
                float t = 1f - Mathf.Clamp(heightDiff / playerThrusterAngleTransitionLength, 0f, 1f);
                Vector2 thrusterAngleRange = playerThrusterAngleRangeMin.LinearInterpolate(playerThrusterAngleRangeMax, t);
                playerTransform = GlobalTransform.AffineInverse() * playerTransform;

                mat.SetShaderParam("playerTransform", playerTransform);
                mat.SetShaderParam("playerThrusterAngleRange", thrusterAngleRange);

                State<Player> playerCurrentState = Player.instance.stateMachine.currentState;
                if (playerCurrentState is PlayerHoverState) {
                    PlayerHoverState state = (PlayerHoverState)playerCurrentState;
                    mat.SetShaderParam("playerThrusterPercentage", state.thrusterT);
                } else {
                    mat.SetShaderParam("playerThrusterPercentage", 0f);
                }
            } else {
                mat.SetShaderParam("playerTransform", Transform2D.Identity);
                mat.SetShaderParam("playerThrusterPercentage", 0f);
            }
        }
    }
}