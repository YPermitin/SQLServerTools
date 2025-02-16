using System;
using YPermitin.SQLCLR.ClickHouseClient.Types.Grammar;

namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal abstract class ParameterizedType : ClickHouseType
    {
        public abstract string Name { get; }

        public abstract ParameterizedType Parse(SyntaxTreeNode typeName, Func<SyntaxTreeNode, ClickHouseType> parseClickHouseTypeFunc, TypeSettings settings);
    }
}