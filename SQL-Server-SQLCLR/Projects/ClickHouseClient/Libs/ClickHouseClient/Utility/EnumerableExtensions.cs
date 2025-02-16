using System;
using System.Collections.Generic;
//using System.Buffers;

namespace YPermitin.SQLCLR.ClickHouseClient.Utility
{
    public static class EnumerableExtensions
    {
        public static void Deconstruct<T>(this IList<T> list, out T first, out T second)
        {
            if (list.Count != 2)
                throw new ArgumentException($"Expected 2 elements in list, got {list.Count}");
            first = list[0];
            second = list[1];
        }

        public static void Deconstruct<T>(this IList<T> list, out T first, out T second, out T third)
        {
            if (list.Count != 3)
                throw new ArgumentException($"Expected 3 elements in list, got {list.Count}");
            first = list[0];
            second = list[1];
            third = list[2];
        }

        public static IEnumerable<(T[], int)> BatchRented<T>(this IEnumerable<T> enumerable, int batchSize)
        {
            List<T> items = new List<T>();

            //var array = ArrayPool<T>.Shared.Rent(batchSize);
            int counter = 0;

            foreach (var item in enumerable)
            {
                //array[counter++] = item;
                counter++;
                items.Add(item);

                if (counter >= batchSize)
                {
                    yield return (items.ToArray(), counter);
                    //yield return (array, counter);
                    counter = 0;
                    //array = ArrayPool<T>.Shared.Rent(batchSize);
                    items = new List<T>();
                }
            }
            if (counter > 0)
                //yield return (array, counter);
                yield return (items.ToArray(), counter);
        }
    }
}