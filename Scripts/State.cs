using System;
using Godot;

public class State<T> : Node {
    public StateMachine<T> stateMachine;
    public T root;

    public State<T> QueryState(string stateName) {
        return stateMachine.QueryState(stateName);
    }

    public B QueryState<B>(string stateName) where B : State<T> {
        return QueryState(stateName) as B;
    }

    public virtual void Enter() {}

    public virtual void Process(float delta) {}

    public virtual void PhysicsProcess(float delta) {}

    public virtual void Exit() {}
}