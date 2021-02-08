using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

namespace ExtensionMethods {
    namespace IEnumerableMethods {
        public struct WeightedItem<T> {
            public T value;
            public float probability;
        }
        public static class IEnumerableExtensionMethods {
            public static T PickRandom<T>(this IEnumerable<T> source) {
                Random random = new Random();
                return source.PickRandom(random);
            }

            public static T PickRandom<T>(this IEnumerable<T> source, Random random)
            {
                return source.PickRandom(1, random).Single();
            }

            public static IEnumerable<T> PickRandom<T>(this IEnumerable<T> source, int count)
            {
                Random random = new Random();
                return source.PickRandom(count, random);
            }

            public static IEnumerable<T> PickRandom<T>(this IEnumerable<T> source, int count, Random random)
            {
                return source.Shuffle(random).Take(count);
            }

            public static T PickRandomByChance<T>(this T[] source, float[] chances) {
                Random random = new Random();
                return source.PickRandomByChance(chances, random);
            }

            public static T PickRandomByChance<T>(this T[] source, float[] chances, Random random) {
                int sourceCount = source.Length;

                if (sourceCount != chances.Length) {
                    throw new System.Exception("The chances list length is not the same as the source count");
                }

                float cummulative = 0f;
                float[] convertedChances = new float[sourceCount];

                for (int i = 0; i < sourceCount; i++) {
                    cummulative += chances[i];
                    convertedChances[i] = cummulative;
                }

                float prob = (float)random.NextDouble() * cummulative;

                T selected = source[0];

                for (int i = 0; i < sourceCount; i++) {
                    if (convertedChances[i] >= prob) {
                        selected = source[i];
                        break;
                    }
                }

                return selected;
            }

            public static IEnumerable<T> Shuffle<T>(this IEnumerable<T> source, Random random, int count = 1)
            {
                while (count > 0) {
                    source = source.OrderBy(x => random.Next());
                    count--;
                }
                return source;
            }
        }
    }
}