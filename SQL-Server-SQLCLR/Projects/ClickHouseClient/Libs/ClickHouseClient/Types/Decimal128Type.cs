using System;
using System.Globalization;
using YPermitin.SQLCLR.ClickHouseClient.Types.Grammar;

namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal class Decimal128Type : DecimalType
    {
        public Decimal128Type()
        {
            Precision = 38;
        }

        public override int Size => 16;

        public override string Name => "Decimal128";

        public override ParameterizedType Parse(SyntaxTreeNode node, Func<SyntaxTreeNode, ClickHouseType> parseClickHouseTypeFunc, TypeSettings settings)
        {
            return new Decimal128Type
            {
                Scale = int.Parse(node.SingleChild.Value, CultureInfo.InvariantCulture),
                UseBigDecimal = settings.useBigDecimal,
            };
        }

        public override string ToString() => $"{Name}({Scale})";
    }
}