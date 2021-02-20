using Godot;
using System;

public class Platform : StaticBody2D
{
    private AnimationPlayer fadeAnim {get; set;}
    private Control platformControl {get; set;}
    private Control lightControl {get; set;}
    private Label multiplierText {get; set;}
    private CollisionShape2D col {get; set;}
    private ParticleSystem2D landParticleSystem {get; set;}

    public float scoreMultiplier = 1f;
    public Vector2 size {get; set;}

    public override void _Ready() {
        fadeAnim = GetNode<AnimationPlayer>("Base/Anim");
        platformControl = GetNode<Control>("Base/Spr");
        lightControl = GetNode<Control>("Base/Spr/Light/Light");
        multiplierText = GetNode<Label>("Multiplier/Text");
        col = GetNode<CollisionShape2D>("Col");
        landParticleSystem = GetNode<ParticleSystem2D>("Landed");
        ParticleSystemEmitOptions landParticleSystemEmitOptions = landParticleSystem.GetModule<ParticleSystemEmitOptions>();
        EmitPlane landParticleSystemEmitPlane = landParticleSystem.GetModule<EmitPlane>();

        RectangleShape2D colShape = new RectangleShape2D();

        multiplierText.Text = scoreMultiplier + "x";
        platformControl.RectPosition = new Vector2(
            -size.x / 2f, 0f
        );
        platformControl.RectSize = size;
        lightControl.RectSize = new Vector2(size.x, lightControl.RectSize.y);
        colShape.Extents = size / 2f;
        col.Shape = colShape;
        col.Position = Vector2.Down * (size.y / 2f + 1f);

        Color c = World.main.surfaceColor;
        c.v += .025f;

        landParticleSystemEmitOptions.startColor = c;
        landParticleSystemEmitPlane.size = size.x / 2f;
    }

    public bool IsInside(float globalX) {
        float localX = globalX - platformControl.RectGlobalPosition.x;
        return localX >= 0f && localX <= size.x;
    }

    public void Land() {
        landParticleSystem.Emit();
        fadeAnim.Play("FadeOut");
    }
}
