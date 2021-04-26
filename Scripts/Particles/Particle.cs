using System;
using System.Collections.Generic;
using Godot;

namespace ParticleSystem
{
    public class Particle
    {
        public int idx { get; set; }

        public Vector3 position {get; set;}
        public Vector3 scale {get; set;}
        public Quat rotation {get; set;}

        public float gravityScale { get; set; }

        public Vector3 velocity { get; set; }
        public float lifetime { get; set; }
        public float life { get; set; }
        public Color color { get; set; }
        public bool persistent { get; set; }

        public Vector3 startPosition {get; set;}
        public Vector3 startScale {get; set;}
        public Quat startRotation {get; set;}
        public Color startColor { get; set; }

        public Dictionary<String, object> customData { get; set; }
        public Color custom { get; set; }

        public bool alive { get; set; }

        public Transform transform {
            get {
                Transform t = Transform.Identity;
                
                t = t.Scaled(scale);
                t = new Transform(rotation, position) * t;

                return t;
            }
        }
    }
}