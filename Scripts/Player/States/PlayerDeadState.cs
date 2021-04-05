using Godot;

public class PlayerDeadState : State<Player> {
    public override void Enter()
    {
        root.LinearVelocity = Vector2.Zero;
        root.AngularVelocity = 0f;

        root.Mode = RigidBody2D.ModeEnum.Static;

        root.body.Hide();

        root.CollisionToggle(false);
        GameCamera.instance.desiredZoom = root.platformZoomRange.y;
    }

    public override void PhysicsProcess(float delta)
    {
        if (Input.IsActionJustPressed("reset_level")) {
            QueryState("Hover");
        }
    }

    public override void Exit()
    {
        root.GlobalTransform = root.startTransform;
        root.Mode = RigidBody2D.ModeEnum.Rigid;

        root.body.Show();

        root.CollisionToggle(true);
    }
}