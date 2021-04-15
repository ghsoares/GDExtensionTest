using Godot;

public class PlayerNextLevelState : State<Player> {
    ShaderMaterial transitionMaterial;
    float currTransitionTime;
    bool nextLevelWaiting = false;

    [Export]
    public float transitionTime = 1f;

    public override void Enter()
    {
        base.Enter();
        transitionMaterial = root.sprite.Material as ShaderMaterial;
        currTransitionTime = transitionTime;

        nextLevelWaiting = false;
    }

    public override void PhysicsProcess(float delta)
    {
        base.PhysicsProcess(delta);
        currTransitionTime -= delta;
        float t = 1f - Mathf.Clamp(currTransitionTime / transitionTime, 0f, 1f);
        transitionMaterial.SetShaderParam("warpTransition", t);
        if (currTransitionTime <= 0f && !nextLevelWaiting) {
            NextLevel();
        }
    }

    private async void NextLevel()
    {
        if (nextLevelWaiting) return;
        nextLevelWaiting = true;
        await LevelTransition.instance.AsyncAnimateIn();
        Planet.instance.Generate();
    }

    public override void Exit()
    {
        transitionMaterial.SetShaderParam("warpTransition", 0f);
        root.GlobalTransform = root.startTransform;
    }
}