using Godot;
using System;

public class PopupText : Node2D
{
    private Node2D pivot {get; set;}
    private Label textLabel {get; set;}
    private Tween motionTween {get; set;}
    private Tween enterExitTween {get; set;}
    private Color[] colors {get; set;}
    private float cycleSpeed {get; set;}
    private float currColorOff {get; set;}
    private bool started {get; set;}
    public int score {get; set;}
    
    [Export]
    public float lifetime = 4f;

    public override void _Ready() {
        pivot = GetNode<Node2D>("Pivot");
        textLabel = GetNode<Label>("Pivot/Text");
        motionTween = new Tween();
        enterExitTween = new Tween();
        AddChild(motionTween);
        AddChild(enterExitTween);
        Scale = Vector2.Zero;
    }

    public void ConfigureText(string text) {
        textLabel.Text = text;
    }

    public void ConfigureMotion(
        Vector2 motion, float duration = 3f, float delay = 0f
    ) {
        motionTween.InterpolateProperty(
            this, "global_position", GlobalPosition, GlobalPosition + motion, duration,
            Tween.TransitionType.Quad, Tween.EaseType.InOut, delay
        );
    }

    public void ConfigureSize(float size = 1f) {
        pivot.Scale = Vector2.One * size;
    }

    public void ConfigureColorCicle(Color[] colors, float cycleSpeed) {
        this.colors = colors;
        this.cycleSpeed = cycleSpeed;
    }

    public override void _PhysicsProcess(float delta) {
        currColorOff += cycleSpeed * delta;
        currColorOff = currColorOff % 1f;
        if (this.colors != null) {
            int idx = Mathf.FloorToInt(colors.Length * currColorOff);
            Color c = colors[idx];
            textLabel.Modulate = c;
        }
    }

    public void Start(float delay = 0f) {
        if (started) return;
        started = true;

        enterExitTween.InterpolateProperty(
            this, "scale", Vector2.Zero, new Vector2(.5f, 1.25f), .25f,
            Tween.TransitionType.Quad, Tween.EaseType.InOut, 0f + delay
        );
        enterExitTween.InterpolateProperty(
            this, "scale", new Vector2(.5f, 1.25f), Vector2.One, .25f,
            Tween.TransitionType.Quad, Tween.EaseType.InOut, .25f + delay
        );
        enterExitTween.Start();
        enterExitTween.Connect("tween_all_completed", this, "Entered");
    }

    private void Entered() {
        enterExitTween.Disconnect("tween_all_completed", this, "Entered");
        motionTween.Start();
        motionTween.Connect("tween_all_completed", this, "Moved");
    }

    private void Moved() {
        motionTween.Disconnect("tween_all_completed", this, "Moved");
        enterExitTween.InterpolateProperty(
            this, "scale", Vector2.One, new Vector2(.5f, 1.25f), .25f,
            Tween.TransitionType.Quad, Tween.EaseType.InOut, 0f
        );
        enterExitTween.InterpolateProperty(
            this, "scale", new Vector2(.5f, 1.25f), Vector2.Zero, .25f,
            Tween.TransitionType.Quad, Tween.EaseType.InOut, .25f
        );
        enterExitTween.Start();
        enterExitTween.Connect("tween_all_completed", this, "Exited");
    }

    private void Exited() {
        QueueFree();
    }
}
