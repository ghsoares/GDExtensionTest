using Godot;

namespace ExtensionMethods {
    namespace ColorMethods {
        public static class ColorExtensionMethods {
            public static Color EncodeFloatIntoColor(float v) {
                Color bitSh = new Color(256f*256f*256f,256f*256f,256f,1f);
                Color bitMsk = new Color(0f,1f/256f,1f/256f,1f/256f);

                Color res = v * bitSh;
                res.r -= Mathf.Floor(res.r);
                res.g -= Mathf.Floor(res.g);
                res.b -= Mathf.Floor(res.b);
                res.a -= Mathf.Floor(res.a);

                res.g -= res.r * bitMsk.g;
                res.b -= res.g * bitMsk.b;
                res.a -= res.b * bitMsk.a;

                return res;
            }
        }
    }
}