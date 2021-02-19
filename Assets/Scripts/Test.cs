using Godot;
using System;

public class Test : Sprite
{
    public override void _Ready()
    {
        GD.Print("Ready!");
    }

    public override void _Process(float delta) {
        GD.Print("Process!");
    }
}
