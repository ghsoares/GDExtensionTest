using Godot;
using System.Collections.Generic;

namespace ExtensionMethods {
    namespace ImageMethods {
        public static class ImageExtensionMethods {
            public static void SetPixels(this Image img, IEnumerable<Color> colorArr) {
                List<byte> bytes = new List<byte>();

                foreach (Color c in colorArr) {
                    List<byte> colorBytes = new List<byte>(GD.Var2Bytes(c));
                    colorBytes.RemoveRange(0, 4);   // First 4 bytes describe the type of the var, not useful here
                    switch (img.GetFormat()) {
                        case Image.Format.Rf: {
                            bytes.AddRange(colorBytes.GetRange(0, 4));
                            break;
                        }
                    }
                }

                img.Data["data"] = bytes.ToArray();
            }
        }
    }
}