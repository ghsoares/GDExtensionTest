using ExtensionMethods.ColorMethods;
using Godot;
using System;

public class Game : Control
{
    public Camera2D zoomCamera {get; private set;}

    public override void _Ready()
    {
        zoomCamera = GetNode<Camera2D>("ZoomCamera");
    }

    public override void _Process(float delta)
    {
        Vector2 onScreenPos = GameCamera.instance.GetGlobalTransformWithCanvas().origin;
        zoomCamera.Position = onScreenPos;
        zoomCamera.Zoom = GameCamera.instance.currentZoom * Vector2.One;
    }
}
