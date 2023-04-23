using System;
using System.Collections.Generic;
using System.Linq;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;
using YPermitin.SQLCLR.YellowMetadataReader.Services;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers.Converters
{
    public sealed class DataTypeInfoConverter : IConfigObjectConverter
    {
        private readonly Dictionary<Guid, Dictionary<string, ApplicationObject>> _referenceBaseTypes = new Dictionary<Guid, Dictionary<string, ApplicationObject>>();
        private Configurator Configurator { get; }
        public DataTypeInfoConverter(Configurator configurator)
        {
            Configurator = configurator;
            _referenceBaseTypes.Add(new Guid("280f5f0e-9c8a-49cc-bf6d-4d296cc17a63"), null); // ЛюбаяСсылка
            _referenceBaseTypes.Add(new Guid("e61ef7b8-f3e1-4f4b-8ac7-676e90524997"), Configurator.InfoBase.Catalogs); // СправочникСсылка
            _referenceBaseTypes.Add(new Guid("38bfd075-3e63-4aaa-a93e-94521380d579"), Configurator.InfoBase.Documents); // ДокументСсылка
            _referenceBaseTypes.Add(new Guid("474c3bf6-08b5-4ddc-a2ad-989cedf11583"), Configurator.InfoBase.Enumerations); // ПеречислениеСсылка
            _referenceBaseTypes.Add(new Guid("0a52f9de-73ea-4507-81e8-66217bead73a"), Configurator.InfoBase.Publications); // ПланОбменаСсылка
            _referenceBaseTypes.Add(new Guid("99892482-ed55-4fb5-a7f7-20888820a758"), Configurator.InfoBase.Characteristics); // ПланВидовХарактеристикСсылка
            _referenceBaseTypes.Add(new Guid("ac606d60-0209-4159-8e4c-794bc091ce38"), Configurator.InfoBase.Accounts); // ПланСчетовСсылка
        }
        public object Convert(ConfigObject configObject)
        {
            DataTypeInfo typeInfo = new DataTypeInfo();

            // 0 = "Pattern"
            int typeOffset = 1;
            List<Guid> typeUuids = new List<Guid>();
            int count = configObject.Values.Count - 1;

            for (int t = 0; t < count; t++)
            {
                // T - type descriptor
                ConfigObject descriptor = configObject.GetObject(new[] { t + typeOffset });

                // T.Q - property type qualifiers
                string[] qualifiers = new string[descriptor.Values.Count];
                for (int q = 0; q < descriptor.Values.Count; q++)
                {
                    qualifiers[q] = configObject.GetString(new[] { t + typeOffset, q });
                }
                if (qualifiers[0] == MetadataTokens.B) typeInfo.CanBeBoolean = true; // {"B"}
                else if (qualifiers[0] == MetadataTokens.S)
                {
                    typeInfo.CanBeString = true; // {"S"} | {"S",10,0} | {"S",10,1}
                    if (qualifiers.Length == 1)
                    {
                        typeInfo.StringLength = -1;
                        typeInfo.StringKind = StringKind.Unlimited;
                    }
                    else
                    {
                        typeInfo.StringLength = int.Parse(qualifiers[1]);
                        typeInfo.StringKind = (StringKind)int.Parse(qualifiers[2]);
                    }
                }
                else if (qualifiers[0] == MetadataTokens.N)
                {
                    typeInfo.CanBeNumeric = true; // {"N",10,2,0} | {"N",10,2,1}
                    typeInfo.NumericPrecision = int.Parse(qualifiers[1]);
                    typeInfo.NumericScale = int.Parse(qualifiers[2]);
                    typeInfo.NumericKind = (NumericKind)int.Parse(qualifiers[3]);
                }
                else if (qualifiers[0] == MetadataTokens.D)
                {
                    typeInfo.CanBeDateTime = true; // {"D"} | {"D","D"} | {"D","T"}
                    if (qualifiers.Length == 1)
                    {
                        typeInfo.DateTimePart = DateTimePart.DateTime;
                    }
                    else if (qualifiers[1] == MetadataTokens.D)
                    {
                        typeInfo.DateTimePart = DateTimePart.Date;
                    }
                    else
                    {
                        typeInfo.DateTimePart = DateTimePart.Time;
                    }
                }
                else if (qualifiers[0] == MetadataTokens.R) // {"#",70497451-981e-43b8-af46-fae8d65d16f2}
                {
                    Guid typeUuid = new Guid(qualifiers[1]);
                    if (typeUuid == new Guid("e199ca70-93cf-46ce-a54b-6edc88c3a296")) // ХранилищеЗначения - varbinary(max)
                    {
                        typeInfo.IsValueStorage = true;
                    }
                    else if (typeUuid == new Guid("fc01b5df-97fe-449b-83d4-218a090e681e")) // УникальныйИдентификатор - binary(16)
                    {
                        typeInfo.IsUuid = true;
                    }
                    else if (_referenceBaseTypes.TryGetValue(typeUuid, out Dictionary<string, ApplicationObject> collection))
                    {
                        if (collection == null) // Любая ссылка
                        {
                            typeInfo.CanBeReference = true;
                            typeUuids.Add(Guid.Empty);
                        }
                        else if (collection.Count == 1) // Единственный объект метаданных в коллекции
                        {
                            typeInfo.CanBeReference = true;
                            typeUuids.Add(collection.Values.First().Uuid);
                        }
                        else // Множественный ссылочный тип данных
                        {
                            typeInfo.CanBeReference = true;
                            typeUuids.Add(Guid.Empty);
                        }
                    }
                    else if (Configurator.InfoBase.CompoundTypes.TryGetValue(typeUuid, out CompoundType compound))
                    {
                        // since 8.3.3
                        Configurator.InfoBase.ApplyCompoundType(typeInfo, compound);
                        typeUuids.Add(compound.TypeInfo.ReferenceTypeUuid);
                    }
                    else if (Configurator.InfoBase.CharacteristicTypes.TryGetValue(typeUuid, out Characteristic characteristic))
                    {
                        Configurator.InfoBase.ApplyCharacteristic(typeInfo, characteristic);
                        typeUuids.Add(characteristic.TypeInfo.ReferenceTypeUuid);
                    }
                    //else if (Configurator.InfoBase.ReferenceTypeUuids.TryGetValue(typeUuid, out ApplicationObject metaObject))
                    //{
                    //    typeInfo.CanBeReference = true;
                    //    typeUuids.Add(typeUuid);
                    //}
                    else
                    {
                        // идентификатор ссылочного типа данных (см. закомментированную ветку выше)
                        // или
                        // идентификатор типа данных (определяемый или характеристика) ещё не загружен
                        // или
                        // неизвестный тип данных (работа с этим типом данных не реализована)
                        typeInfo.CanBeReference = true;
                        typeUuids.Add(typeUuid);
                    }
                }
            }
            if (typeUuids.Count == 1) // single type value
            {
                typeInfo.ReferenceTypeUuid = typeUuids[0];
            }

            return typeInfo;
        }
    }
}