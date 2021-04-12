using System;
using System.Collections.Generic;
using ExtensionMethods.Shape2DExtensions;
using ExtensionMethods.Transform2DMethods;
using Godot;

public class WaterAgent : Node2D
{
    public enum CollisionDetectionMode {
        BoundingBox,
        CollisionShapes
    }

    class ColShapeData
    {
        public uint ownerIdx { get; set; }
        public int shapeIdx { get; set; }
        public Shape2D shape { get; set; }
        public Godot.Object shapeOwner { get; set; }
        public Transform2D transform { get; set; }
    }

    class CollidedLiquidBodyData {
        public LiquidBody body {get; set;}
        public List<LiquidBody.LiquidSurfacePoint> collidedPoints {get; set;}
    }

    public bool debug {get; set;}

    Rect2 globalRect {get; set;}
    RigidBody2D rb { get; set; }
    List<ColShapeData> collisionShapes { get; set; }
    Dictionary<LiquidBody, CollidedLiquidBodyData> insideBodies {get; set;}

    [Export] public Rect2 bounds = new Rect2(-Vector2.One * 8f, Vector2.One * 16f);
    [Export] public CollisionDetectionMode collisionDetectionMode = CollisionDetectionMode.BoundingBox;

    [Signal] delegate void OnLiquidBodyEnter(LiquidBody body);
    [Signal] delegate void OnLiquidBodyExit(LiquidBody body);

    public override void _Ready()
    {
        rb = GetParent<RigidBody2D>();
        if (rb == null)
        {
            GD.PushError("WaterAgent must be a direct agent of a RigidBody2D");
            QueueFree();
            return;
        }
        collisionShapes = new List<ColShapeData>();
        insideBodies = new Dictionary<LiquidBody, CollidedLiquidBodyData>();
        foreach (int i in rb.GetShapeOwners())
        {
            for (int j = 0; j < rb.ShapeOwnerGetShapeCount((uint)i); j++)
            {
                collisionShapes.Add(new ColShapeData()
                {
                    ownerIdx = (uint)i,
                    shapeIdx = j,
                    shape = rb.ShapeOwnerGetShape((uint)i, j),
                    shapeOwner = rb.ShapeOwnerGetOwner((uint)i)
                });
            }
        }
    }

    public override void _Process(float delta)
    {
        Update();
    }

    public override void _PhysicsProcess(float delta)
    {
        globalRect = GlobalTransform.Xform(bounds);
        foreach (ColShapeData colShape in collisionShapes)
        {
            colShape.transform = rb.ShapeOwnerGetTransform(colShape.ownerIdx);
            if (colShape.shapeOwner is CanvasItem)
            {
                CanvasItem canvasItem = (CanvasItem)colShape.shapeOwner;
                colShape.transform = canvasItem.GetGlobalTransform() * colShape.transform;
            }
        }
        CollisionCheck(delta);
        foreach (CollidedLiquidBodyData colData in insideBodies.Values) {
            foreach (LiquidBody.LiquidSurfacePoint colP in colData.collidedPoints) {
                colData.body.ApplyForce(colP.idx, (rb.LinearVelocity.y + Mathf.Abs(rb.LinearVelocity.x)) * 2f);
            }
            rb.LinearVelocity -= rb.LinearVelocity * Mathf.Clamp(colData.body.drag * delta, 0f, 1f);
        }
    }

    public bool Collide(Vector2 p, float margin = 0f) {
        if (collisionDetectionMode == CollisionDetectionMode.BoundingBox) {
            return globalRect.Grow(margin).HasPoint(p);
        } else {
            foreach (ColShapeData shapeData in collisionShapes) {
                Shape2D shape = shapeData.shape;
                Transform2D transform = shapeData.transform;

                if (shape.HasPoint(p, transform, margin)) return true;
            }
        }

        return false;
    }

    public bool Inside(Vector2 p, Rect2 limit) {
        if (collisionDetectionMode == CollisionDetectionMode.BoundingBox) {
            p.y = Mathf.Clamp(GlobalPosition.y, p.y, limit.End.y);
            return globalRect.HasPoint(p);
        } else {
            foreach (ColShapeData shapeData in collisionShapes) {
                Shape2D shape = shapeData.shape;
                Transform2D transform = shapeData.transform;

                p.y = Mathf.Clamp(transform.origin.y, p.y, limit.End.y);

                if (shape.HasPoint(p, transform)) return true;
            }
        }

        return false;
    }

    private void CollisionCheck(float delta)
    {
        int idx = 0;
        foreach (LiquidBody liquid in LiquidBody.activeBodies)
        {
            List<LiquidBody.LiquidSurfacePoint> points = liquid.GetSurfacePointsInBounds(globalRect);
            List<LiquidBody.LiquidSurfacePoint> collidedPoints = new List<LiquidBody.LiquidSurfacePoint>();
            bool inside = false;
            float margin = 0f;
            if (points.Count > 0) {
                Rect2 liquidGlobalRect = liquid.GetGlobalRect();

                foreach (LiquidBody.LiquidSurfacePoint p in points) {
                    if (inside) margin = 16f;

                    if (Collide(p.pos, margin)) {
                        inside = true;
                        collidedPoints.Add(p);
                    }

                    inside |= Inside(p.pos, liquidGlobalRect);
                }
            }

            CollidedLiquidBodyData bodyData;

            if (inside) {
                if (!insideBodies.ContainsKey(liquid)) {
                    bodyData = new CollidedLiquidBodyData {body = liquid, collidedPoints = collidedPoints};
                    insideBodies.Add(liquid, bodyData);
                    EmitSignal("OnLiquidBodyEnter", liquid);
                } else {
                    bodyData = insideBodies[liquid];
                }
                bodyData.collidedPoints = collidedPoints;
            } else {
                if (insideBodies.ContainsKey(liquid)) {
                    insideBodies.Remove(liquid);
                    EmitSignal("OnLiquidBodyExit", liquid);
                }
            }

            idx++;
        }
    }

    public override void _Draw()
    {
        base._Draw();
        if (!debug) return;
        DrawSetTransformMatrix(GlobalTransform.AffineInverse());
        Rect2 globalRect = GlobalTransform.Xform(bounds);

        DrawRect(globalRect, new Color(.25f, .25f, 1f, .5f));

        foreach (LiquidBody liquid in LiquidBody.activeBodies)
        {
            List<LiquidBody.LiquidSurfacePoint> points = liquid.GetSurfacePointsInBounds(globalRect);
            foreach (LiquidBody.LiquidSurfacePoint p in points)
            {
                Color color = Colors.Red;
                
                foreach (ColShapeData colShape in collisionShapes)
                {
                    Shape2D shape = colShape.shape;
                    Transform2D transform = colShape.transform;

                    if (Collide(p.pos))
                    {
                        color = Colors.Green;
                    }
                }
                
                DrawCircle(p.pos, 1f, color);
            }
        }
    }
}
