using Godot;
using System;

namespace ExtensionMethods {
    namespace RandomMethods {
        public static class RandomExtensionMethods {
            public static float NextFloat(this Random random) {
                return (float)random.NextDouble();
            }

            public static float NextFloat(this Random random, float min, float max) {
                return Mathf.Lerp(min, max, random.NextFloat());
            }
        }
    }
}