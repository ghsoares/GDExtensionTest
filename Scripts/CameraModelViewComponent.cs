using System;
using Godot;

[Tool]
public class CameraModelViewComponent : ModelViewComponent
{
    protected override void UpdateTransform()
    {
        base.UpdateTransform();
        Vector2 size = GetViewport().Size;
        float zBase = Mathf.Min(size.x, size.y);
        if (modelNode is Camera && viewNode is Camera2D)
        {
            Camera modelCamera = modelNode as Camera;
            Camera2D viewCamera = viewNode as Camera2D;

            float z = modelCamera.Size;
            z /= (zBase * pixelSize);
            
            if (z > 0f)
            {
                viewCamera.Zoom = Vector2.One * z;
            }
            viewCamera.Current = modelCamera.Current;
            viewCamera.OffsetH = modelCamera.HOffset / pixelSize;
            viewCamera.OffsetV = modelCamera.VOffset / pixelSize;
        }
        else if (modelNode is Camera2D && viewNode is Camera)
        {
            Camera2D modelCamera = modelNode as Camera2D;
            Camera viewCamera = viewNode as Camera;

            float z = Mathf.Max(modelCamera.Zoom.x, modelCamera.Zoom.y);
            z *= (zBase * pixelSize);

            if (z > 0f)
            {
                viewCamera.Size = z;
            }
            viewCamera.Current = modelCamera.Current;
            viewCamera.HOffset = modelCamera.OffsetH * pixelSize;
            viewCamera.VOffset = modelCamera.OffsetV * pixelSize;
        }
    }
}
