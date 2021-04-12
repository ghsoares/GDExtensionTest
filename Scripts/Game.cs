using Godot;
using System;

public class Game : Control
{
    public Viewport view;
    public Camera2D zoomCamera;
    public Planet planet;

    public override void _Ready()
    {
        base._Ready();

        Engine.TargetFps = 30;

        view = GetNode<Viewport>("View");
        zoomCamera = GetNode<Camera2D>("ZoomCamera");
        planet = GetNode<Planet>("View/Planet");

        PlayerData.ResetSession();
    }

    public override void _Input(InputEvent ev)
    {
        view.Input(ev);
    }

    public override void _PhysicsProcess(float delta)
    {
        UpdateCamera();
    }

    public void UpdateCamera() {
        if (planet.generating) return;

        GameCamera gameCamera = GameCamera.instance;
        Vector2 cameraScPos = gameCamera.GetGlobalTransformWithCanvas().origin;

        zoomCamera.Zoom = Vector2.One * gameCamera.currentZoom;
        zoomCamera.Position = cameraScPos;

        zoomCamera.ForceUpdateScroll();
    }
}
