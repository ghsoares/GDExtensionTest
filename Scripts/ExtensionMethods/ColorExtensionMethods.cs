using System;
using Godot;

namespace ExtensionMethods
{
    namespace ColorMethods
    {
        public static class ColorExtensionMethods
        {
            public static Color EncodeFloat(float value) {
                uint val = BitConverter.ToUInt32(BitConverter.GetBytes(value), 0);
                return Color.Color8(
                    (byte)(val & 0xFF),
                    (byte)((val >> 8) & 0xFF),
                    (byte)((val >> 16) & 0xFF),
                    (byte)((val >> 24) & 0xFF)
                );
                /*(byte)(value & 0xFF), 
                    (byte)((value >> 8) & 0xFF), 
                    (byte)((value >> 16) & 0xFF), 
                    (byte)((value >> 24) & 0xFF) };
        }*/
                /*public static byte[] GetBytes(uint value)
                {
                    return new byte[4] { 
                            (byte)(value & 0xFF), 
                            (byte)((value >> 8) & 0xFF), 
                            (byte)((value >> 16) & 0xFF), 
                            (byte)((value >> 24) & 0xFF) };
                }*/
            }
        }
    }
}