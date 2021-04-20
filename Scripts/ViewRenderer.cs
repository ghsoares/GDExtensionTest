using System;
using System.Collections.Generic;
using Godot;

public class ViewRenderer : TextureRect
{
    public override void _Ready()
    {
        GenerateBloomShaderCode(2);
    }

    private void GenerateBloomShaderCode(int size = 1)
    {
        Shader shader = (Material as ShaderMaterial)?.Shader;

        int totalSize = (size * 2 + 1) * (size * 2 + 1);

        int i = 0;

        List<String> code = new List<String>();

        code.Add("shader_type canvas_item;");
        code.Add("uniform float threshold = 1f;");
        code.Add("uniform float intensity = 1f;");
        code.Add("void fragment() {");
        code.Add("\tvec4 col = texture(TEXTURE, UV);");
        code.Add("\tvec3 bloom = vec3(0f);");

        List<String> offArr = new List<String>();
        List<String> weightArr = new List<String>();

        float totalW = 0f;

        for (int x = -size; x <= size; x++) {
            for (int y = -size; y <= size; y++) {
                Vector2 off = new Vector2(x, y);
                float w = 1f - Mathf.Clamp((off.Length() - 1f) / size, 0f, 1f);

                offArr.Add($"vec2({off.x}f, {off.y}f)");
                weightArr.Add(($"{w}f").Replace(",", "."));

                totalW += w;

                i++;
            }
        }

        code.Add($"\tvec2 offArr[{totalSize}] = vec2[{totalSize}] ({String.Join(", ", offArr)});");
        code.Add($"\tfloat weightArr[{totalSize}] = float[{totalSize}] ({String.Join(", ", weightArr)});");

        code.Add($"\tfor (int i = 0; i < {totalSize}; i++) {{");
        code.Add("\t\tvec3 thisPix = texture(TEXTURE, UV + offArr[i] * TEXTURE_PIXEL_SIZE).rgb;");
        code.Add("\t\tthisPix = max(thisPix - threshold, 0f) * (1f + threshold);");
        code.Add("\t\tbloom += thisPix * weightArr[i];");
        code.Add("\t}");

        code.Add(($"\tcol.rgb += (bloom / {totalW}f) * intensity;").Replace(",", "."));
        code.Add("\tCOLOR = col;");

        code.Add("}");
        
        if (shader != null) {
            Console.WriteLine(String.Join("\n", code).Replace("\t", "    "));
        }
    }
}
