﻿using System;
using System.Globalization;
using YPermitin.SQLCLR.ClickHouseClient.Types.Grammar;

namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal class Decimal64Type : DecimalType
    {
        public Decimal64Type()
        {
            Precision = 18;
        }

        public override int Size => 8;

        public override string Name => "Decimal64";

        public override ParameterizedType Parse(SyntaxTreeNode node, Func<SyntaxTreeNode, ClickHouseType> parseClickHouseTypeFunc, TypeSettings settings) => new Decimal64Type
        {
            Scale = int.Parse(node.SingleChild.Value, CultureInfo.InvariantCulture),
            UseBigDecimal = settings.useBigDecimal,
        };

        public override string ToString() => $"{Name}({Scale})";
    }
}