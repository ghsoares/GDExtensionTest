using Godot;

public class Platform : Node2D {
    public Control baseColor;
    public Control lightColor;
    public Control light2Color;
    public Label scoreMultiplierLabel;
    public ShaderMaterial lightMaterial;

    public float scoreMultiplier = 5f;
    public float size;

    public override void _Ready()
    {
        baseColor = GetNode<Control>("Base/Color");
        lightColor = GetNode<Control>("Light/Color");
        light2Color = GetNode<Control>("Light2/Color");
        scoreMultiplierLabel = GetNode<Label>("Base/Color/Label");
        lightMaterial = lightColor.Material as ShaderMaterial;
    }

    public void InitControl() {
        size = 20f + (5f - (scoreMultiplier - 1f)) * 8f;

        baseColor.RectSize = new Vector2(size, baseColor.RectSize.y);
        baseColor.RectPosition = Vector2.Left * size * .5f;

        lightColor.RectSize = new Vector2(size, lightColor.RectSize.y);
        lightColor.RectPosition = new Vector2(-size * .5f, -lightColor.RectSize.y);

        light2Color.RectSize = new Vector2(size, light2Color.RectSize.y);
        light2Color.RectPosition = new Vector2(-size * .5f, -light2Color.RectSize.y);

        scoreMultiplierLabel.Text = "X" + scoreMultiplier;
    }

    /*public override void _Process(float delta) {
        Player player = Player.instance;
        Vector2 localPlayerPos = lightColor.GetGlobalTransform().XformInv(player.GlobalPosition);

        lightMaterial.SetShaderParam("playerPosition", localPlayerPos);
    }*/

    public float GetDistanceX(float x) {
        //return max(abs(fromX - position.x) - size / 2.0, 0.0)
        return Mathf.Max(Mathf.Abs(x - GlobalPosition.x) - size * .5f, 0f);
    }
}