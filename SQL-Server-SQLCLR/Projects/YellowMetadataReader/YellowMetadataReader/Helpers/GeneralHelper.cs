using System;
using YPermitin.SQLCLR.YellowMetadataReader.Models;

namespace YPermitin.SQLCLR.YellowMetadataReader.Helpers
{
    public static class GeneralHelper
    {
        public static string GenerateConfigFullObjectKey(Guid uuid, string token, int code)
        {
            return $"{uuid}_{token}_{code}";
        }

        public static string GetMetadataTypeByToken(string token)
        {
            string metadataType;

            switch (token)
            {
                case MetadataTokens.Reference:
                    metadataType = "Справочник";
                    break;
                case MetadataTokens.Document:
                    metadataType = "Документ";
                    break;
                case MetadataTokens.Const:
                    metadataType = "Константа";
                    break;
                case MetadataTokens.Acc:
                    metadataType = "ПланСчетов";
                    break;
                case MetadataTokens.Node:
                    metadataType = "ПланОбмена";
                    break;
                case MetadataTokens.Enum:
                    metadataType = "Перечисление";
                    break;
                case MetadataTokens.InfoRg:
                    metadataType = "РегистрСведений";
                    break;
                case MetadataTokens.AccumRg:
                    metadataType = "РегистрНакопления";
                    break;
                case MetadataTokens.AccumRgT:
                    metadataType = "РегистрНакопления";
                    break;
                case MetadataTokens.AccumRgChngR:
                    metadataType = "РегистрНакопления";
                    break;
                case MetadataTokens.AccumRgOpt:
                    metadataType = "РегистрНакопления";
                    break;
                case MetadataTokens.AccRg:
                    metadataType = "РегистрБухгалтерии";
                    break;
                case MetadataTokens.Chrc:
                    metadataType = "ПланВидовХарактеристик";
                    break;
                default:
                    metadataType = "Unspecified";
                    break;
            }

            return metadataType;
        }
    }
}
