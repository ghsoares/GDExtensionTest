using Godot;
using System;

[Tool]
public class Platform : StaticBody2D
{
    private Control platformControl {get; set;}
    private Label multiplierText {get; set;}
    private CollisionShape2D col {get; set;}
    private ParticleSystem2D landParticleSystem {get; set;}

    public float scoreMultiplier = 1f;
    public Vector2 size {get; set;}

    public override void _Ready() {
        if (Engine.EditorHint) return;

        platformControl = GetNode<Control>("Spr");
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
        colShape.Extents = size / 2f;
        col.Shape = colShape;

        Color c = World.main.surfaceColor;
        c.v += .01f;

        landParticleSystemEmitOptions.startColor = c;
        landParticleSystemEmitPlane.size = size.x / 2f;
    }

    public bool IsInside(float globalX) {
        float localX = globalX - platformControl.RectGlobalPosition.x;
        return localX >= 0f && localX <= size.x;
    }

    public void Land() {
        landParticleSystem.Emit();
        platformControl.Hide();
        multiplierText.Hide();
    }
}
