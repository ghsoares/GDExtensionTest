using Godot;
using System.Collections.Generic;
using System;

public class Particle {
        public int idx {get; set;}

        public Vector2 position {get; set;}
	    public Vector2 size {get; set;}
	    public float rotation {get; set;}

        public float gravityScale {get; set;}

        public Vector2 velocity {get; set;}
	    public float lifetime {get; set;}
	    public float life {get; set;}
	    public Color color {get; set;}
	    public bool persistent {get; set;}

        public Vector2 startSize {get; set;}
	    public Color startColor {get; set;}

        public Dictionary<String, object> customData {get; set;}

        public bool alive {get; set;}

        public Transform2D transform {
            get {
                Transform2D t = Transform2D.Identity;

                t.Scale = size;
                t.Rotation = rotation;
                t.origin = position;

                return t;
            }
        }
    }