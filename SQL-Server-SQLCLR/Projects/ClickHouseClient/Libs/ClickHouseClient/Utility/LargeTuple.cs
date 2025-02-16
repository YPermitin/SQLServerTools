#if !NET462
using System.Runtime.CompilerServices;

namespace YPermitin.SQLCLR.ClickHouseClient.Utility
{
    internal class LargeTuple : ITuple
    {
        private readonly object[] items;

        public LargeTuple(params object[] items)
        {
            this.items = items;
        }

        public object this[int index] => items[index];

        public int Length => items.Length;
    }
}
#endif