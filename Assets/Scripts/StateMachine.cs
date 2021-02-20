using System.Collections.Generic;

public class State<T> {
    public T root;
    public StateMachine<T> stateMachine;
    public string name;
    public float deltaTime;
    public float fixedDeltaTime;

    protected State<T> GetStateByName(string name) {
        if (!stateMachine.states.ContainsKey(name)) {
            throw new System.Exception("The state with the name '" + name +"' doesn't exist!");
        }
        return stateMachine.states[name];
    }

    protected B GetStateByName<B>(string name) where B : State<T> {
        return (B)GetStateByName(name);
    }

    public virtual void Init() {}

    public virtual bool QueryEnter() {return true;}
    public virtual void Enter() {}

    public virtual void UpdateState() {}
    public virtual void FixedUpdateState() {}

    public virtual void Exit() {}
}

public class StateMachine<T> {
    public T root {get; private set;}
    public Dictionary<string, State<T>> states {get; private set;}

    private State<T> currentState {get; set;}
    private State<T> querriedState {get; set;}

    public StateMachine(T root) {
        this.root = root;
        this.states = new Dictionary<string, State<T>>();
    }

    public B AddState<B>(string name) where B : State<T>, new() {
        State<T> state = new B();

        states.Add(name, state);
        state.root = root;
        state.stateMachine = this;
        state.name = name;

        return (B)state;
    }

    public void Init(string startState) {
        this.Init(states[startState]);
    }

    public void Init(State<T> startState) {
        foreach (State<T> state in states.Values) {
            state.Init();
        }
        this.currentState = startState;
    }

    public bool ChangeState(State<T> newState) {
        if (!newState.QueryEnter()) return false;
        if (currentState != null) {
            currentState.Exit();
        }
        currentState = newState;
        newState.Enter();
        return true;
    }

    public void QueryState(State<T> state) {
        querriedState = state;
    }

    public void Update(float deltaTime) {
        currentState.deltaTime = deltaTime;
        currentState.UpdateState();
        if (querriedState != null) {
            if (ChangeState(querriedState)) {
                querriedState = null;
            }
        }
    }

    public void FixedUpdate(float deltaTime) {
        currentState.fixedDeltaTime = deltaTime;
        currentState.FixedUpdateState();
        if (querriedState != null) {
            if (ChangeState(querriedState)) {
                querriedState = null;
            }
        }
    }
}

