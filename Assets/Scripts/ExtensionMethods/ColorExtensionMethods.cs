using Godot;

namespace ExtensionMethods {
    namespace ColorMethods {
        public static class ColorExtensionMethods {
            public static float Luminance(this Color color) {
                return (.2126f*color.r + .7152f*color.g + .0722f*color.b);
            }
        }
    }
}