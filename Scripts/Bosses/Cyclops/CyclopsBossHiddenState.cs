<<<<<<< HEAD
using Godot;

public class CyclopsBossHiddenState : State<CyclopsBoss> {
    private float currTime {get; set;}

    [Export] public float time = 5f;

    public override void Enter()
    {
        currTime = time;
    }

    public override void PhysicsProcess(float delta)
    {
        currTime -= delta;
        if (currTime <= 0f) {
            QueryState("Jump");
        }
    }
=======
using Godot;

public class CyclopsBossHiddenState : State<CyclopsBoss> {
    private float currTime {get; set;}

    [Export] public float time = 5f;

    public override void Enter()
    {
        currTime = time;
    }

    public override void PhysicsProcess(float delta)
    {
        currTime -= delta;
        if (currTime <= 0f) {
            QueryState("Jump");
        }
    }
>>>>>>> 169bcf1c52691ab1634d5e844e9575f2036eb400
}