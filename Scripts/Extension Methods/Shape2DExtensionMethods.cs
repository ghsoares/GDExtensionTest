using Godot;

namespace ExtensionMethods {
    namespace Shape2DExtensions {
        public static class Shape2DExtensionMethods {
            public static bool HasPoint(this Shape2D shape, Vector2 point, Transform2D shapeTransform, float margin = 0f) {
                if (shape is CircleShape2D) {
                    return (shape as CircleShape2D).HasPoint(point, shapeTransform, margin);
                } else if (shape is RectangleShape2D) {
                    return (shape as RectangleShape2D).HasPoint(point, shapeTransform, margin);
                } else if (shape is CapsuleShape2D) {
                    return (shape as CapsuleShape2D).HasPoint(point, shapeTransform, margin);
                }
                return false;
            }

            public static bool HasPoint(this CircleShape2D shape, Vector2 point, Transform2D shapeTransform, float margin = 0f) {
                point = shapeTransform.XformInv(point);
                float radius = shape.Radius + margin;
                return point.Length() <= radius;
            }

            public static bool HasPoint(this RectangleShape2D shape, Vector2 point, Transform2D shapeTransform, float margin = 0f) {
                point = shapeTransform.XformInv(point);
                Vector2 extents = shape.Extents + Vector2.One * margin;
                bool insideX = point.x >= -extents.x && point.x <= extents.x;
                bool insideY = point.y >= -extents.y && point.y <= extents.y;
                return insideX && insideY;
            }

            public static bool HasPoint(this CapsuleShape2D shape, Vector2 point, Transform2D shapeTransform, float margin = 0f) {                
                point = shapeTransform.XformInv(point);

                float circleRadius = shape.Radius + margin;
                float height = shape.Height + margin;

                Vector2 circle1 = new Vector2(0f, height / 2f);
                Vector2 circle2 = new Vector2(0f, -height / 2f);

                bool insideCircles = (circle1 - point).Length() <= circleRadius || (circle2 - point).Length() <= circleRadius;
                bool insideRectX = point.x >= -circleRadius && point.x <= circleRadius;
                bool insideRectY = point.y >= -height * .5f && point.y <= height * .5f;

                return insideCircles || (insideRectX && insideRectY);
            }
        }
    }
}