using System.Collections.Generic;
using System.Linq;
using Godot;

namespace ExtensionMethods
{
    namespace NodeMethods
    {
        public static class NodeExtensionMethods
        {
            public static List<Node> GetChildNodes(this Node root, bool recursive = false)
            {
                List<Node> thisChildren = new List<Node>();

                foreach (Node c in root.GetChildren())
                {
                    thisChildren.Add(c);
                    if (recursive)
                    {
                        thisChildren.AddRange(c.GetChildNodes(recursive));
                    }
                }

                return thisChildren;
            }

            public static List<T> GetChildNodes<T>(this Node root, bool recursive = false) where T : Node
            {
                return root.GetChildNodes(recursive).OfType<T>().ToList();
            }
        }
    }
}