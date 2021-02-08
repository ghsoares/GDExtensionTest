using Godot;

namespace ExtensionMethods {
    namespace Transform2DMethods {
        public static class Transform2DExtensionMethods {
            public static Rect2 Xform(this Transform2D t, Rect2 rect) {
                Vector2 x = t.x * rect.Size.x;
                Vector2 y = t.y * rect.Size.y;
                Vector2 pos = t.Xform(rect.Position);

                Rect2 newRect = new Rect2();
                newRect.Position = pos;
                newRect = newRect.Expand(pos + x);
                newRect = newRect.Expand(pos + y);
                newRect = newRect.Expand(pos + x + y);

                return newRect;
            }

            public static Rect2 XformInv(this Transform2D t, Rect2 rect) {
                Vector2[] ends = new Vector2[] {
                    t.XformInv(rect.Position),
                    t.XformInv(new Vector2(rect.Position.x, rect.Position.y + rect.Size.y)),
                    t.XformInv(new Vector2(rect.Position.x + rect.Size.x, rect.Position.y + rect.Size.y)),
                    t.XformInv(new Vector2(rect.Position.x + rect.Size.x, rect.Position.y)),
                };

                Rect2 newRect = new Rect2();

                newRect.Position = ends[0];
                newRect = newRect.Expand(ends[1]);
                newRect = newRect.Expand(ends[2]);
                newRect = newRect.Expand(ends[3]);

                return newRect;
            }
        }
    }
}