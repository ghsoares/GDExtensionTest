using Godot;
using System;

public class Clouds : Control
{
    private Viewport viewport {get; set;}
    private ColorRect noiseColorRect {get; set;}
    private TextureRect renderColorRect {get; set;}
    private CloudsFadeParticleSystem fadeTrail {get; set;}
    private Vector2 prevPlayerDirection {get; set;}

    public float height = 256;
    public ShaderMaterial cloudsNoiseMaterial;
    public ShaderMaterial cloudsRenderingMaterial;

    public void Setup() {
        Viewport baseView = GetViewport();
        RectSize = new Vector2(baseView.Size.x, height);
        if (viewport == null) {
            viewport = new Viewport();
            viewport.Size = new Vector2(baseView.Size.x, RectSize.y);
            viewport.TransparentBg = true;
            viewport.Usage = Viewport.UsageEnum.Usage2dNoSampling;
            viewport.RenderTargetVFlip = true;
            AddChild(viewport);
        }
        if (noiseColorRect == null) {
            noiseColorRect = new ColorRect();
            noiseColorRect.AnchorRight = 1f;
            noiseColorRect.AnchorBottom = 1f;
            noiseColorRect.Material = cloudsNoiseMaterial;
            viewport.AddChild(noiseColorRect);
        }
        if (fadeTrail == null) {
            fadeTrail = ResourceLoader.Load<PackedScene>("res://Scenes/CloudsFade.tscn").Instance() as CloudsFadeParticleSystem;
            viewport.AddChild(fadeTrail);
        }
        if (renderColorRect == null) {
            renderColorRect = new TextureRect();
            renderColorRect.AnchorRight = 1f;
            renderColorRect.AnchorBottom = 1f;
            renderColorRect.Material = cloudsRenderingMaterial;
            
            renderColorRect.Texture = viewport.GetTexture();

            AddChild(renderColorRect);
        }
    }

    public override void _PhysicsProcess(float delta)
    {
        Viewport baseView = GetViewport();
        Transform2D canvasTransform = baseView.CanvasTransform;
        Transform2D globalCanvasTransform = canvasTransform.AffineInverse();

        canvasTransform.origin = new Vector2(canvasTransform.origin.x, -RectGlobalPosition.y);

        renderColorRect.RectPosition = new Vector2(globalCanvasTransform.origin.x, RectGlobalPosition.y);
        noiseColorRect.RectPosition = new Vector2(globalCanvasTransform.origin.x, RectGlobalPosition.y);

        if (cloudsNoiseMaterial != null) {
            cloudsNoiseMaterial.SetShaderParam("globalTransform", noiseColorRect.GetGlobalTransform());
        }
        if (Player.instance != null & Player.instance.IsInsideTree()) {
            Vector2 direction = Player.instance.LinearVelocity.Normalized();
            if (direction != Vector2.Zero) {
                prevPlayerDirection = direction;
            }
            fadeTrail.GlobalPosition = Player.instance.GlobalPosition + Vector2.Up * RectGlobalPosition.y;
        }

        viewport.CanvasTransform = canvasTransform;
    }
}
