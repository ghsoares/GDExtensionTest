using Godot;
using System;

public class WorldCamera : Camera2D
{
    public Vector2 position {get; set;}

    public override void _PhysicsProcess(float delta) {
        Vector2 pos = GlobalPosition;
        
        pos = position;
        pos.x = Mathf.Floor(pos.x);
        pos.y = Mathf.Floor(pos.y);

        GlobalPosition = pos;
    }
}
