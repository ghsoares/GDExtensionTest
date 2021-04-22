using Godot;

public class CyclopsBossDeadState : State<CyclopsBoss> {
    public override void Enter()
    {
        root.EmitSignal("Dead");
    }
}