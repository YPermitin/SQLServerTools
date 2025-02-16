using System;
using System.Globalization;
using YPermitin.SQLCLR.ClickHouseClient.Types.Grammar;

namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal class Decimal256Type : DecimalType
    {
        public Decimal256Type()
        {
            Precision = 76;
        }

        public override int Size => 32;

        public override string Name => "Decimal256";

        public override ParameterizedType Parse(SyntaxTreeNode node, Func<SyntaxTreeNode, ClickHouseType> parseClickHouseTypeFunc, TypeSettings settings)
        {
            return new Decimal256Type
            {
                Scale = int.Parse(node.SingleChild.Value, CultureInfo.InvariantCulture),
                UseBigDecimal = settings.useBigDecimal,
            };
        }

        public override string ToString() => $"{Name}({Scale})";
    }
}