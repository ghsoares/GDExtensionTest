using Godot;
using System;

public class WorldCamera : Camera2D
{
    public Vector2 desiredPosition {get; set;}

    public override void _PhysicsProcess(float delta) {
        Vector2 pos = GlobalPosition;
        
        pos = desiredPosition;
        pos.x = Mathf.Floor(pos.x);
        pos.y = Mathf.Floor(pos.y);

        GlobalPosition = pos;
    }
}
