using Godot;


public class Trail2D : Line2D
{
    public Vector2 headPosition { get; set; }

    [Export] public int numPoints = 8;
    [Export] public float spacing = 16f;

    public override void _Ready()
    {
        base._Ready();
        TextureMode = LineTextureMode.Stretch;
        for (int i = 0; i < numPoints; i++)
        {
            AddPoint(GlobalPosition);
        }
        ShaderMaterial shaderMaterial = Material as ShaderMaterial;
        if (shaderMaterial != null) {
            shaderMaterial.SetShaderParam("lineSize", numPoints * spacing);
        }
    }

    public void Warp(Vector2 position)
    {
        headPosition = position;
        for (int i = 0; i < numPoints; i++)
        {
            SetPointPosition(i, headPosition);
        }
    }

    public void MoveTo(Vector2 position)
    {
        float deltaLen = (headPosition - position).Length();
        for (int i = 0; i < numPoints - 1; i++) {
            Vector2 curr = GetPointPosition(i);
            Vector2 nxt = GetPointPosition(i+1);

            float t = Mathf.Clamp(deltaLen / spacing, 0f, 1f);

            curr = curr.LinearInterpolate(nxt, t);

            SetPointPosition(i, curr);
        }
        headPosition = position;
        SetPointPosition(numPoints - 1, headPosition);
    }
}