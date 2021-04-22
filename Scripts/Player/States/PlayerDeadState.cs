using Godot;

public class PlayerDeadState : State<Player>
{
    bool resetting = false;

    public override void Enter()
    {
        root.LinearVelocity = Vector2.Zero;
        root.AngularVelocity = 0f;

        root.Mode = RigidBody2D.ModeEnum.Static;

        root.body.Hide();

        root.CollisionToggle(false);

        root.dead = true;

        root.explosionParticleSystem.Emit();

        root.GlobalPosition = Vector2.One * -128f;

        resetting = false;

        GameCamera.instance.desiredZoom = 1f;
    }

    public override void PhysicsProcess(float delta)
    {
        if (Input.IsActionJustPressed("reset_level") && !resetting)
        {
            Reset();
        }
    }

    private async void Reset()
    {
        if (resetting) return;
        resetting = true;
        await LevelTransition.instance.AsyncAnimateIn();
        QueryState("Hover");
    }

    public override void Exit()
    {
        root.GlobalTransform = root.startTransform;
        root.Mode = RigidBody2D.ModeEnum.Rigid;

        root.body.Show();

        root.CollisionToggle(true);
    }
}