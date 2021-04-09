using Godot;
using System;

public class GameCamera : Camera2D
{
    public static GameCamera instance;

    public float desiredZoom = 1f;
    public Vector2 desiredPosition;
    public Vector2 currentPosition;
    public float currentZoom;

    [Export]
    public float lerpSpeed = 4f;

    public GameCamera() {
        instance = this;
        Current = true;
        ProcessMode = Camera2DProcessMode.Physics;
    }

    public override void _Ready() {
        desiredPosition = GlobalPosition;
        desiredZoom = Zoom.x;
        currentPosition = GlobalPosition;
        currentZoom = desiredZoom;

        LimitLeft = 0;
        LimitTop = 0;
        LimitRight = Mathf.FloorToInt(Planet.instance.size.x);
        LimitBottom = Mathf.FloorToInt(Planet.instance.size.y);
        LimitSmoothed = true;
    }

    public override void _PhysicsProcess(float delta) {
        desiredPosition.x = Mathf.Clamp(desiredPosition.x, LimitLeft, LimitRight);
        desiredPosition.y = Mathf.Clamp(desiredPosition.y, LimitTop, LimitBottom);
        desiredZoom = Mathf.Clamp(desiredZoom, 0.001f, 1f);

        currentPosition = currentPosition.LinearInterpolate(desiredPosition, Mathf.Min(1f, delta * lerpSpeed));
        currentZoom = Mathf.Lerp(currentZoom, desiredZoom, Mathf.Min(1f, delta * lerpSpeed));
        
        GlobalPosition = currentPosition;

        /*GlobalPosition = new Vector2(
            Mathf.Floor(currentPosition.x),
            Mathf.Floor(currentPosition.y)
        );*/

        //Zoom = Vector2.One * currentZoom;

        ForceUpdateScroll();
    }
}
