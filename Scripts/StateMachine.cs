using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public class StateMachine<T> : Node {
    public Dictionary<String, State<T>> states;
    public State<T> currentState;
    public State<T> querriedState;
    public T root;

    public override void _Ready()
    {
        states = new Dictionary<string, State<T>>();

        foreach (Node c in GetChildren()) {
            if (c is State<T>) {
                State<T> state = (State<T>)c;
                state.stateMachine = this;
                states[state.Name] = state;
            }
        }
    }

    public void Start() {
        ChangeState(states.Values.ElementAt(0));
    }

    public void Stop() {
        currentState = null;
        querriedState = null;
    }

    public State<T> QueryState(String stateName) {
        querriedState = states[stateName];
        return querriedState;
    }

    public void ChangeState(State<T> newState) {
        if (currentState != null) {
            currentState.Exit();
        }
        currentState = newState;
        currentState.root = root;
        currentState.Enter();
    }

    public override void _Process(float delta)
    {
        if (currentState != null) {
            currentState.Process(delta);
            if (querriedState != null) {
                ChangeState(querriedState);
                querriedState = null;
            }
        }
    }

    public override void _PhysicsProcess(float delta)
    {
        if (currentState != null) {
            currentState.PhysicsProcess(delta);
            if (querriedState != null) {
                ChangeState(querriedState);
                querriedState = null;
            }
        }
    }
}