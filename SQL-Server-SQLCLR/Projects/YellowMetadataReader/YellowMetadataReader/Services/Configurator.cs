using System;
using System.Collections.Generic;
using System.Linq;
using YPermitin.SQLCLR.YellowMetadataReader.Enrichers;
using YPermitin.SQLCLR.YellowMetadataReader.Enrichers.Converters;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Interfaces;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;

namespace YPermitin.SQLCLR.YellowMetadataReader.Services
{
    public sealed class Configurator
    {
        internal InfoBase InfoBase;
        internal readonly IConfigFileReader FileReader;
        internal readonly ISqlMetadataReader SqlMetadataReader;
        private readonly Dictionary<Type, IContentEnricher> _enrichers = new Dictionary<Type, IContentEnricher>();
        private readonly Dictionary<Type, IConfigObjectConverter> _converters = new Dictionary<Type, IConfigObjectConverter>();

        private readonly Dictionary<string, Type> _metadataTypes = new Dictionary<string, Type>()
        {
            { MetadataTokens.Acc, typeof(Account) },
            { MetadataTokens.AccRg, typeof(AccountingRegister) },
            { MetadataTokens.AccumRg, typeof(AccumulationRegister) },
            { MetadataTokens.Reference, typeof(Catalog) },
            { MetadataTokens.Chrc, typeof(Characteristic) },
            { MetadataTokens.Const, typeof(Constant) },
            { MetadataTokens.Document, typeof(Document) },
            { MetadataTokens.Enum, typeof(Enumeration) },
            { MetadataTokens.InfoRg, typeof(InformationRegister) },
            { MetadataTokens.Node, typeof(Publication) },
            { MetadataTokens.VT, typeof(TablePart) },
            { MetadataTokens.AccumRgT, typeof(AccumulationRegisterTotal) }
        };
        private readonly Dictionary<Type, Func<ApplicationObject>> _factories = new Dictionary<Type, Func<ApplicationObject>>()
        {
            { typeof(Account), () => { return new Account(); } },
            { typeof(AccountingRegister), () => { return new AccountingRegister(); } },
            { typeof(AccumulationRegister), () => { return new AccumulationRegister(); } },
            { typeof(Catalog), () => { return new Catalog(); } },
            { typeof(Characteristic), () => { return new Characteristic(); } },
            { typeof(Constant), () => { return new Constant(); } },
            { typeof(Document), () => { return new Document(); } },
            { typeof(Enumeration), () => { return new Enumeration(); } },
            { typeof(InformationRegister), () => { return new InformationRegister(); } },
            { typeof(Publication), () => { return new Publication(); } },
            { typeof(TablePart), () => { return new TablePart(); } },
            { typeof(AccumulationRegisterTotal), () => { return new AccumulationRegisterTotal(); } },
            { typeof(ApplicationObject), () => { return new ApplicationObject(); } }
        };
        
        public Configurator(IConfigFileReader fileReader, ISqlMetadataReader sqlMetadataReader)
        {
            FileReader = fileReader ?? throw new ArgumentNullException();
            SqlMetadataReader = sqlMetadataReader ?? throw new ArgumentNullException();

            InfoBase = new InfoBase();
            InitializeConverters();
            InitializeEnrichers();
        }

        private void InitializeConverters()
        {
            _converters.Add(typeof(DataTypeInfo), new DataTypeInfoConverter(this));
        }
        private void InitializeEnrichers()
        {
            _enrichers.Add(typeof(DbNamesEnricher), new DbNamesEnricher(this));
            _enrichers.Add(typeof(InfoBase), new InfoBaseEnricher(this));
            _enrichers.Add(typeof(Enumeration), new EnumerationEnricher(this));
            _enrichers.Add(typeof(Catalog), new CatalogEnricher(this));
            _enrichers.Add(typeof(Characteristic), new CharacteristicEnricher(this));
            _enrichers.Add(typeof(Document), new DocumentEnricher(this));
            _enrichers.Add(typeof(Publication), new PublicationEnricher(this));
            _enrichers.Add(typeof(InformationRegister), new InformationRegisterEnricher(this));
            _enrichers.Add(typeof(AccumulationRegister), new AccumulationRegisterEnricher(this));
            _enrichers.Add(typeof(AccumulationRegisterTotal), new AccumulationRegisterTotalEnricher(this));
            _enrichers.Add(typeof(Constant), new ConstantEnricher(this));
            _enrichers.Add(typeof(Account), new AccountEnricher(this));
            _enrichers.Add(typeof(AccountingRegister), new AccountingRegisterEnricher(this));
        }

        public InfoBase OpenInfoBase(OpenInfobaseLevel level = OpenInfobaseLevel.ConfigFull)
        {
            try
            {
                GetEnricher(typeof(DbNamesEnricher)).Enrich(InfoBase);
            }
            catch (Exception error)
            {
                throw new Exception("Failed to load [DBNames] params file.", error);
            }

            try
            {
                GetEnricher<InfoBase>().Enrich(InfoBase);
            }
            catch (Exception error)
            {
                throw new Exception("Failed to load [root] config file.", error);
            }

            if (level == OpenInfobaseLevel.ConfigFull)
            {
                OpenInfoBaseSynchronously();
            }

            return InfoBase;
        }
        private bool TryEnrichMetadataObject(IContentEnricher enricher, MetadataObject metadataObject)
        {
            if (enricher == null) throw new ArgumentNullException(nameof(TryEnrichMetadataObject) + "(" + nameof(enricher) + ")");
            if (metadataObject == null) throw new ArgumentNullException(nameof(TryEnrichMetadataObject) + "(" + nameof(metadataObject) + ")");

            try
            {
                enricher.Enrich(metadataObject);
                return true;
            }
            catch
            {
                return false;
            }
        }
        private void OpenInfoBaseSynchronously()
        {
            IContentEnricher enricher = GetEnricher<Enumeration>();
            foreach (var o in InfoBase.Enumerations.Values)
            {
                var enumeration = (Enumeration)o;
                if (TryEnrichMetadataObject(enricher, enumeration))
                {
                    _ = InfoBase.ReferenceTypeUuids.TryAdd(enumeration.FullKey, enumeration);
                    _ = InfoBase.ReferenceTypeCodes.TryAdd(enumeration.TypeCode, enumeration);
                }
            }

            enricher = GetEnricher<Characteristic>();
            foreach (var o in InfoBase.Characteristics.Values)
            {
                var characteristic = (Characteristic)o;
                if (TryEnrichMetadataObject(enricher, characteristic))
                {
                    InfoBase.CharacteristicTypes.Add(characteristic.TypeUuid, characteristic);
                    _ = InfoBase.ReferenceTypeUuids.TryAdd(characteristic.FullKey, characteristic);
                    _ = InfoBase.ReferenceTypeCodes.TryAdd(characteristic.TypeCode, characteristic);
                }
            }

            enricher = GetEnricher<Catalog>();
            foreach (var o in InfoBase.Catalogs.Values)
            {
                var catalog = (Catalog)o;
                if (TryEnrichMetadataObject(enricher, catalog))
                {
                    _ = InfoBase.ReferenceTypeUuids.TryAdd(catalog.FullKey, catalog);
                    _ = InfoBase.ReferenceTypeCodes.TryAdd(catalog.TypeCode, catalog);
                }
            }

            enricher = GetEnricher<Document>();
            foreach (var o in InfoBase.Documents.Values)
            {
                var document = (Document)o;
                if (TryEnrichMetadataObject(enricher, document))
                {
                    _ = InfoBase.ReferenceTypeUuids.TryAdd(document.FullKey, document);
                    _ = InfoBase.ReferenceTypeCodes.TryAdd(document.TypeCode, document);
                }
            }

            enricher = GetEnricher<Publication>();
            foreach (var o in InfoBase.Publications.Values)
            {
                var publication = (Publication)o;
                if (TryEnrichMetadataObject(enricher, publication))
                {
                    _ = InfoBase.ReferenceTypeUuids.TryAdd(publication.FullKey, publication);
                    _ = InfoBase.ReferenceTypeCodes.TryAdd(publication.TypeCode, publication);
                }
            }

            enricher = GetEnricher<InformationRegister>();
            foreach (var o in InfoBase.InformationRegisters.Values)
            {
                var register = (InformationRegister)o;
                _ = TryEnrichMetadataObject(enricher, register);
            }

            enricher = GetEnricher<AccumulationRegister>();
            foreach (var o in InfoBase.AccumulationRegisters.Values)
            {
                var register = (AccumulationRegister)o;
                _ = TryEnrichMetadataObject(enricher, register);
            }

            enricher = GetEnricher<Constant>();
            foreach (var o in InfoBase.Constants.Values)
            {
                var register = (Constant)o;
                _ = TryEnrichMetadataObject(enricher, register);
            }

            enricher = GetEnricher<Account>();
            foreach (var o in InfoBase.Accounts.Values)
            {
                var register = (Account)o;
                _ = TryEnrichMetadataObject(enricher, register);
            }

            enricher = GetEnricher<AccountingRegister>();
            foreach (var o in InfoBase.AccountingRegisters.Values)
            {
                var register = (AccountingRegister)o;
                _ = TryEnrichMetadataObject(enricher, register);
            }

            enricher = GetEnricher<AccumulationRegisterTotal>();
            var accumulationRegisterTotals = InfoBase
                .AccumulationRegisters.Values
                .SelectMany(e => e.NestedObjects)
                .Where(e => e is AccumulationRegisterTotal)
                .ToList();
            foreach (var o in accumulationRegisterTotals)
            {
                var register = (AccumulationRegisterTotal)o;
                _ = TryEnrichMetadataObject(enricher, register);
            }
        }
        
        #region "DbNames"

        public string CreateDbName(string token, int code)
        {
            if (code <= 0)
            {
                return $"_{token}";
            }
            else
            {
                return $"_{token}{code}";
            }
        }
        public Type GetTypeByToken(string token)
        {
            if (string.IsNullOrWhiteSpace(token)) return null;

            if (_metadataTypes.TryGetValue(token, out Type type))
            {
                return type;
            }
            return typeof(ApplicationObject);
        }
        public Func<ApplicationObject> GetFactory(string token)
        {
            Type type = GetTypeByToken(token);
            if (type == null) return null;

            if (_factories.TryGetValue(type, out Func<ApplicationObject> factory))
            {
                return factory;
            }

            return null;
        }
        public ApplicationObject CreateObject(Guid uuid, string token, int code)
        {
            Func<ApplicationObject> factory = GetFactory(token);
            if (factory == null) return null;

            ApplicationObject metaObject = factory();
            metaObject.FileName = uuid;
            metaObject.TypeCode = code;
            metaObject.Token = token;
            metaObject.TableName = CreateDbName(token, code);

            return metaObject;
        }
        public MetadataProperty CreateProperty(Guid uuid, string token, int code)
        {
            return new MetadataProperty()
            {
                Uuid = uuid,
                FileName = uuid,
                DbName = CreateDbName(token, code)
            };
        }

        #endregion

        public IContentEnricher GetEnricher<T>() where T : MetadataObject
        {
            return GetEnricher(typeof(T));
        }
        public IContentEnricher GetEnricher(Type type)
        {
            if (_enrichers.TryGetValue(type, out IContentEnricher enricher))
            {
                return enricher;
            }
            return null;
        }
        public IConfigObjectConverter GetConverter<T>()
        {
            return GetConverter(typeof(T));
        }
        public IConfigObjectConverter GetConverter(Type type)
        {
            if (_converters.TryGetValue(type, out IConfigObjectConverter converter))
            {
                return converter;
            }
            return null;
        }

        public void ConfigureProperties(ApplicationObject metaObject, ConfigObject properties, PropertyPurpose purpose)
        {
            int propertiesCount = properties.GetInt32(new[] { 1 }); // количество реквизитов
            if (propertiesCount == 0) return;

            int propertyOffset = 2;
            for (int p = 0; p < propertiesCount; p++)
            {
                // P.0.1.1.1.1.2 - property uuid
                Guid propertyUuid = properties.GetUuid(new[] { p + propertyOffset, 0, 1, 1, 1, 1, 2 });
                // P.0.1.1.1.2 - property name
                string propertyName = properties.GetString(new[] { p + propertyOffset, 0, 1, 1, 1, 2 });
                // P.0.1.1.1.3 - property alias descriptor
                string propertyAlias = string.Empty;
                ConfigObject aliasDescriptor = properties.GetObject(new[] { p + propertyOffset, 0, 1, 1, 1, 3 });
                if (aliasDescriptor.Values.Count == 3)
                {
                    // P.0.1.1.1.3.2 - property alias
                    propertyAlias = properties.GetString(new[] { p + propertyOffset, 0, 1, 1, 1, 3, 2 });
                }
                // P.0.1.1.2 - property types
                ConfigObject propertyTypes = properties.GetObject(new[] { p + propertyOffset, 0, 1, 1, 2 });
                // P.0.1.1.2.0 = "Pattern"
                DataTypeInfo typeInfo = (DataTypeInfo)GetConverter<DataTypeInfo>().Convert(propertyTypes);

                // P.0.3 - property usage for catalogs and characteristics
                int propertyUsage = -1;
                if (metaObject is Catalog || metaObject is Characteristic)
                {
                    propertyUsage = properties.GetInt32(new[] { p + propertyOffset, 0, 3 });
                }

                ConfigureProperty(metaObject, purpose, propertyUuid, propertyName, propertyAlias, typeInfo, propertyUsage);
            }
        }
        public void ConfigureProperty(ApplicationObject metaObject, PropertyPurpose purpose, Guid fileName, string name, string alias, DataTypeInfo type, int propertyUsage)
        {
            if (!InfoBase.PropertiesById.TryGetValue(fileName, out MetadataProperty property)) return;

            // TODO Проверяем существует ли это поле в базе данных
            // Если нет, то проверяем некоторые другие правила формирования полей.
            // Если правила не подходят, то добавляем поле как есть в любом случае.
            // metaObject.TableName
            // property.DbName
            if (metaObject is AccountingRegister)
            {
                var dbTableFields = SqlMetadataReader.GetSqlFieldsOrderedByName(metaObject.TableName);
                if (!dbTableFields.Any(e => e.COLUMN_NAME == property.DbName))
                {
                    // Поля БД не найдено. Пытаемся определить есть ли соответствующие поля ДТ / КТ
                    string newDatabaseFieldNameDt = $"{property.DbName}DtRRef";
                    bool fieldDbDtExists = dbTableFields.Any(e => e.COLUMN_NAME == newDatabaseFieldNameDt);
                    if (!fieldDbDtExists)
                    {
                        newDatabaseFieldNameDt = $"{property.DbName}Dt";
                        fieldDbDtExists = dbTableFields.Any(e => e.COLUMN_NAME == newDatabaseFieldNameDt);
                    }
                    string newDatabaseFieldNameCt = $"{property.DbName}CtRRef";
                    bool fieldDbCtExists = dbTableFields.Any(e => e.COLUMN_NAME == newDatabaseFieldNameCt);
                    if (!fieldDbCtExists)
                    {
                        newDatabaseFieldNameCt = $"{property.DbName}Ct";
                        fieldDbCtExists = dbTableFields.Any(e => e.COLUMN_NAME == newDatabaseFieldNameCt);
                    }

                    if (fieldDbDtExists && fieldDbCtExists)
                    {
                        MetadataProperty newPropertyDt = new MetadataProperty();
                        newPropertyDt.DbName = newDatabaseFieldNameDt;
                        newPropertyDt.Name = $"{name}Дт";
                        newPropertyDt.Alias = $"{alias} Дт";
                        newPropertyDt.Purpose = purpose;
                        newPropertyDt.PropertyType = type;
                        newPropertyDt.Fields = property.Fields;
                        newPropertyDt.PropertyUsage = property.PropertyUsage;
                        newPropertyDt.Uuid = property.Uuid;
                        newPropertyDt.FileName = property.FileName;
                        if (propertyUsage != -1)
                        {
                            newPropertyDt.PropertyUsage = (PropertyUsage)propertyUsage;
                        }

                        metaObject.Properties.Add(newPropertyDt);
                        ConfigureDatabaseFields(newPropertyDt);

                        MetadataProperty newPropertyCt = new MetadataProperty();
                        newPropertyCt.DbName = newDatabaseFieldNameCt;
                        newPropertyCt.Name = $"{name}Кт";
                        newPropertyCt.Alias = $"{alias} Кт";
                        newPropertyCt.Purpose = purpose;
                        newPropertyCt.PropertyType = type;
                        newPropertyCt.Fields = property.Fields;
                        newPropertyCt.PropertyUsage = property.PropertyUsage;
                        newPropertyCt.Uuid = property.Uuid;
                        newPropertyCt.FileName = property.FileName;
                        if (propertyUsage != -1)
                        {
                            newPropertyCt.PropertyUsage = (PropertyUsage)propertyUsage;
                        }

                        metaObject.Properties.Add(newPropertyCt);
                        ConfigureDatabaseFields(newPropertyCt);

                        return;
                    }
                }
            }

            property.Name = name;
            property.Alias = alias;
            property.Purpose = purpose;
            property.PropertyType = type;
            if (propertyUsage != -1)
            {
                property.PropertyUsage = (PropertyUsage)propertyUsage;
            }
            metaObject.Properties.Add(property);

            ConfigureDatabaseFields(property);
        }

        public void ConfigureSharedProperties(ApplicationObject metaObject)
        {
            foreach (SharedProperty property in InfoBase.SharedProperties.Values)
            {
                if (property.UsageSettings.TryGetValue(metaObject.FileName, out SharedPropertyUsage usage))
                {
                    if (usage == SharedPropertyUsage.Use)
                    {
                        metaObject.Properties.Add(property);
                    }
                }
                else // Auto
                {
                    if (property.AutomaticUsage == AutomaticUsage.Use)
                    {
                        metaObject.Properties.Add(property);
                    }
                }
            }
        }

        #region "TableParts"

        public void ConfigureTableParts(ApplicationObject owner, ConfigObject tableParts)
        {
            int tablePartsCount = tableParts.GetInt32(new[] { 1 }); // количество табличных частей
            if (tablePartsCount == 0) return;

            int offset = 2;
            for (int t = 0; t < tablePartsCount; t++)
            {
                // T.0.1.5.1.1.2 - uuid табличной части
                Guid uuid = tableParts.GetUuid(new[] { t + offset, 0, 1, 5, 1, 1, 2 });
                // T.0.1.5.1.2 - имя табличной части
                string name = tableParts.GetString(new[] { t + offset, 0, 1, 5, 1, 2 });
                if (InfoBase.TablePartsById.TryGetValue(uuid, out ApplicationObject tablePart))
                {
                    if (tablePart is TablePart)
                    {
                        tablePart.Name = name;
                        ((TablePart)tablePart).Owner = owner;
                        tablePart.TableName = owner.TableName + tablePart.TableName;
                        owner.TableParts.Add((TablePart)tablePart);

                        // T.2 - коллекция реквизитов табличной части (ConfigObject)
                        // T.2.0 = 888744e1-b616-11d4-9436-004095e12fc7 - идентификатор коллекции реквизитов табличной части
                        // T.2.1 - количество реквизитов табличной части
                        Guid collectionUuid = tableParts.GetUuid(new[] { t + offset, 2, 0 });
                        if (collectionUuid == new Guid("888744e1-b616-11d4-9436-004095e12fc7"))
                        {
                            ConfigurePropertyСсылка(owner, tablePart);
                            ConfigurePropertyКлючСтроки(tablePart);
                            ConfigurePropertyНомерСтроки(tablePart);

                            ConfigObject properties = tableParts.GetObject(new[] { t + offset, 2 });
                            ConfigureProperties(tablePart, properties, PropertyPurpose.Property);
                        }
                    }
                }
            }
        }
        private void ConfigurePropertyСсылка(ApplicationObject owner, ApplicationObject tablePart)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Ссылка",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = owner.TableName + "_IDRRef"
            };
            property.PropertyType.IsUuid = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 16,
                TypeName = "binary",
                KeyOrdinal = 1,
                IsPrimaryKey = true
            });
            tablePart.Properties.Add(property);
        }
        private void ConfigurePropertyКлючСтроки(ApplicationObject tablePart)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "КлючСтроки",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_KeyField"
            };
            property.PropertyType.IsBinary = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 4,
                TypeName = "binary",
                KeyOrdinal = 2,
                IsPrimaryKey = true
            });
            tablePart.Properties.Add(property);
        }
        private void ConfigurePropertyНомерСтроки(ApplicationObject tablePart)
        {
            if (!InfoBase.Properties.TryGetValue(tablePart.FullKey, out MetadataProperty property)) return;

            property.Name = "НомерСтроки";
            property.PropertyType.CanBeNumeric = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 5,
                Precision = 5,
                TypeName = "numeric"
            });

            tablePart.Properties.Add(property);
        }

        #endregion

        public void ConfigureDatabaseFields(MetadataProperty property)
        {
            if (property.PropertyType.IsMultipleType)
            {
                ConfigureDatabaseFieldsForMultipleType(property);
            }
            else
            {
                ConfigureDatabaseFieldsForSingleType(property);
            }
        }
        private void ConfigureDatabaseFieldsForSingleType(MetadataProperty property)
        {
            if (property.PropertyType.IsUuid)
            {
                property.Fields.Add(new DatabaseField(property.DbName, "binary", 16));
            }
            else if (property.PropertyType.IsBinary)
            {
                // is used only for system properties of system types
                // TODO: log if it happens eventually
            }
            else if (property.PropertyType.IsValueStorage)
            {
                property.Fields.Add(new DatabaseField(property.DbName, "varbinary", -1));
            }
            else if (property.PropertyType.CanBeString)
            {
                if (property.PropertyType.StringKind == StringKind.Fixed)
                {
                    property.Fields.Add(new DatabaseField(property.DbName, "nchar", property.PropertyType.StringLength));
                }
                else
                {
                    property.Fields.Add(new DatabaseField(property.DbName, "nvarchar", property.PropertyType.StringLength));
                }
            }
            else if (property.PropertyType.CanBeNumeric)
            {
                // length can be updated from database
                property.Fields.Add(new DatabaseField(
                    property.DbName,
                    "numeric", 9,
                    property.PropertyType.NumericPrecision,
                    property.PropertyType.NumericScale));
            }
            else if (property.PropertyType.CanBeBoolean)
            {
                property.Fields.Add(new DatabaseField(property.DbName, "binary", 1));
            }
            else if (property.PropertyType.CanBeDateTime)
            {
                // length, precision and scale can be updated from database
                property.Fields.Add(new DatabaseField(property.DbName, "datetime2", 6, 19, 0));
            }
            else if (property.PropertyType.CanBeReference)
            {
                property.Fields.Add(new DatabaseField(property.DbName + MetadataTokens.RRef, "binary", 16));
            }
        }
        private void ConfigureDatabaseFieldsForMultipleType(MetadataProperty property)
        {
            property.Fields.Add(new DatabaseField(property.DbName + "_" + MetadataTokens.TYPE, "binary", 1)
            {
                Purpose = FieldPurpose.Discriminator
            });

            if (property.PropertyType.CanBeString)
            {
                if (property.PropertyType.StringKind == StringKind.Fixed)
                {
                    property.Fields.Add(new DatabaseField(
                        property.DbName + "_" + MetadataTokens.S,
                        "nchar",
                        property.PropertyType.StringLength)
                    {
                        Purpose = FieldPurpose.String
                    });
                }
                else
                {
                    property.Fields.Add(new DatabaseField(
                        property.DbName + "_" + MetadataTokens.S,
                        "nvarchar",
                        property.PropertyType.StringLength)
                    {
                        Purpose = FieldPurpose.String
                    });
                }
            }
            if (property.PropertyType.CanBeNumeric)
            {
                // length can be updated from database
                property.Fields.Add(new DatabaseField(
                    property.DbName + "_" + MetadataTokens.N,
                    "numeric", 9,
                    property.PropertyType.NumericPrecision,
                    property.PropertyType.NumericScale)
                {
                    Purpose = FieldPurpose.Numeric
                });

            }
            if (property.PropertyType.CanBeBoolean)
            {
                property.Fields.Add(new DatabaseField(property.DbName + "_" + MetadataTokens.L, "binary", 1)
                {
                    Purpose = FieldPurpose.Boolean
                });
            }
            if (property.PropertyType.CanBeDateTime)
            {
                // length, precision and scale can be updated from database
                property.Fields.Add(new DatabaseField(property.DbName + "_" + MetadataTokens.T, "datetime2", 6, 19, 0)
                {
                    Purpose = FieldPurpose.DateTime
                });
            }
            if (property.PropertyType.CanBeReference)
            {
                if (property.PropertyType.ReferenceTypeUuid == Guid.Empty) // miltiple refrence type
                {
                    property.Fields.Add(new DatabaseField(property.DbName + "_" + MetadataTokens.RTRef, "binary", 4)
                    {
                        Purpose = FieldPurpose.TypeCode
                    });
                }
                property.Fields.Add(new DatabaseField(property.DbName + "_" + MetadataTokens.RRRef, "binary", 16)
                {
                    Purpose = FieldPurpose.Object
                });
            }
        }

        #region "Reference type system properties"

        public void ConfigurePropertyСсылка(ApplicationObject metaObject)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Ссылка",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_IDRRef"
            };
            property.PropertyType.IsUuid = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 16,
                TypeName = "binary",
                KeyOrdinal = 1,
                IsPrimaryKey = true
            });
            metaObject.Properties.Add(property);
        }
        public void ConfigurePropertyВерсияДанных(ApplicationObject metaObject)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "ВерсияДанных",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Version"
            };
            property.PropertyType.IsBinary = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 8,
                TypeName = "timestamp"
            });
            metaObject.Properties.Add(property);
        }
        public void ConfigurePropertyПометкаУдаления(ApplicationObject metaObject)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "ПометкаУдаления",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Marked"
            };
            property.PropertyType.CanBeBoolean = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 1,
                TypeName = "binary"
            });
            metaObject.Properties.Add(property);
        }
        public void ConfigurePropertyПредопределённый(ApplicationObject metaObject)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Предопределённый",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_PredefinedID"
            };
            property.PropertyType.IsUuid = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 16,
                TypeName = "binary"
            });
            metaObject.Properties.Add(property);
        }
        public void ConfigurePropertyКод(ApplicationObject metaObject)
        {
            if (!(metaObject is IReferenceCode code)) throw new ArgumentOutOfRangeException();

            MetadataProperty property = new MetadataProperty()
            {
                Name = "Код",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Code"
            };
            if (code.CodeType == CodeType.String)
            {
                property.PropertyType.CanBeString = true;
                property.Fields.Add(new DatabaseField()
                {
                    Name = property.DbName,
                    Length = code.CodeLength,
                    TypeName = "nvarchar"
                });
            }
            else
            {
                property.PropertyType.CanBeNumeric = true;
                property.Fields.Add(new DatabaseField()
                {
                    Name = property.DbName,
                    Precision = code.CodeLength,
                    TypeName = "numeric"
                });
            }
            metaObject.Properties.Add(property);
        }
        public void ConfigurePropertyНаименование(ApplicationObject metaObject)
        {
            if (!(metaObject is IDescription description)) throw new ArgumentOutOfRangeException();

            MetadataProperty property = new MetadataProperty()
            {
                Name = "Наименование",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Description"
            };
            property.PropertyType.CanBeString = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = description.DescriptionLength,
                TypeName = "nvarchar"
            });
            metaObject.Properties.Add(property);
        }
        public void ConfigurePropertyРодитель(ApplicationObject metaObject)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Родитель",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_ParentIDRRef"
            };
            property.PropertyType.CanBeReference = true;
            property.PropertyType.ReferenceTypeUuid = metaObject.Uuid;
            property.PropertyType.ReferenceTypeCode = metaObject.TypeCode;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 16,
                TypeName = "binary"
            });
            metaObject.Properties.Add(property);
        }
        public void ConfigurePropertyЭтоГруппа(ApplicationObject metaObject)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "ЭтоГруппа",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Folder"
            };
            property.PropertyType.CanBeBoolean = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 1,
                TypeName = "binary"
            });
            metaObject.Properties.Add(property);
        }
        public void ConfigurePropertyВладелец(Catalog catalog, Guid owner)
        {
            MetadataProperty property = new MetadataProperty
            {
                Name = "Владелец",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_OwnerID"
            };
            property.PropertyType.CanBeReference = true;

            if (catalog.Owners == 1) // Single type value
            {
                property.PropertyType.ReferenceTypeUuid = owner;
                property.Fields.Add(new DatabaseField()
                {
                    Name = "_OwnerIDRRef",
                    Length = 16,
                    TypeName = "binary"
                });
            }
            else // Multiple type value
            {
                property.Fields.Add(new DatabaseField()
                {
                    Name = "_OwnerID_TYPE",
                    Length = 1,
                    TypeName = "binary",
                    Purpose = FieldPurpose.Discriminator
                });
                property.Fields.Add(new DatabaseField()
                {
                    Name = "_OwnerID_RTRef",
                    Length = 4,
                    TypeName = "binary",
                    Purpose = FieldPurpose.TypeCode
                });
                property.Fields.Add(new DatabaseField()
                {
                    Name = "_OwnerID_RRRef",
                    Length = 16,
                    TypeName = "binary",
                    Purpose = FieldPurpose.Object
                });
            }

            catalog.Properties.Add(property);
        }

        #endregion

        #region "Characteristic properties"

        public void ConfigurePropertyТипЗначения(Characteristic characteristic)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "ТипЗначения",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Type"
            };
            property.PropertyType.IsBinary = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = -1,
                IsNullable = true,
                TypeName = "varbinary"
            });
            characteristic.Properties.Add(property);
        }

        #endregion

        #region "Document system properties"

        public void ConfigurePropertyДата(Document document)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Дата",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Date_Time"
            };
            property.PropertyType.CanBeDateTime = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 6,
                Precision = 19,
                TypeName = "datetime2"
            });
            document.Properties.Add(property);
        }
        public void ConfigurePropertyПериодичность(Document document)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "ПериодНомера",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_NumberPrefix"
            };
            property.PropertyType.CanBeDateTime = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 6,
                Precision = 19,
                TypeName = "datetime2"
            });
            document.Properties.Add(property);
        }
        public void ConfigurePropertyПроведён(Document document)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Проведён",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Posted"
            };
            property.PropertyType.CanBeBoolean = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 1,
                TypeName = "binary"
            });
            document.Properties.Add(property);
        }
        public void ConfigurePropertyНомер(Document document)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Номер",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Number"
            };
            if (document.NumberType == NumberType.Number)
            {
                property.PropertyType.CanBeNumeric = true;
                property.Fields.Add(new DatabaseField()
                {
                    Name = property.DbName,
                    Length = 6,
                    Precision = 19,
                    TypeName = "numeric"
                });
            }
            else
            {
                property.PropertyType.CanBeString = true;
                property.PropertyType.StringKind = StringKind.Fixed;
                property.PropertyType.StringLength = document.NumberLength;
                property.Fields.Add(new DatabaseField()
                {
                    Name = property.DbName,
                    Length = document.NumberLength,
                    TypeName = "nvarchar"
                });
            }
            document.Properties.Add(property);
        }

        // Используется для сихронизации добавления свойства "Регистратор" между документами
        private readonly object _syncRegister = new object();
        public void ConfigurePropertyРегистратор(ApplicationObject register, Document document)
        {
            lock (_syncRegister)
            {
                ConfigurePropertyРегистраторSynchronized(register, document);
            }
        }
        private void ConfigurePropertyРегистраторSynchronized(ApplicationObject register, Document document)
        {
            MetadataProperty property = register.Properties.Where(p => p.Name == "Регистратор").FirstOrDefault();

            if (property == null)
            {
                // добавляем новое свойство
                property = new MetadataProperty()
                {
                    Name = "Регистратор",
                    Purpose = PropertyPurpose.System,
                    FileName = Guid.Empty,
                    DbName = "_Recorder"
                };
                property.PropertyType.CanBeReference = true;
                property.PropertyType.ReferenceTypeUuid = document.Uuid; // single type value
                property.PropertyType.ReferenceTypeCode = document.TypeCode; // single type value
                property.Fields.Add(new DatabaseField()
                {
                    Name = "_RecorderRRef",
                    Length = 16,
                    TypeName = "binary",
                    Scale = 0,
                    Precision = 0,
                    IsNullable = false,
                    KeyOrdinal = 0,
                    IsPrimaryKey = true,
                    Purpose = FieldPurpose.Value
                });
                register.Properties.Add(property);
                return;
            }

            // На всякий случай проверям повторное обращение одного и того же документа
            if (property.PropertyType.ReferenceTypeUuid == document.Uuid) return;

            // Проверям необходимость добавления поля для хранения кода типа документа
            if (property.PropertyType.ReferenceTypeUuid == Guid.Empty) return;

            // Изменяем назначение поля для хранения ссылки на документ, предварительно убеждаясь в его наличии
            DatabaseField field = property.Fields.Where(f => f.Name.ToLowerInvariant() == "_recorderrref").FirstOrDefault();
            if (field != null)
            {
                field.Purpose = FieldPurpose.Object;
            }

            // Добавляем поле для хранения кода типа документа, предварительно убеждаясь в его отсутствии
            if (property.Fields.Where(f => f.Name.ToLowerInvariant() == "_recordertref").FirstOrDefault() == null)
            {
                property.Fields.Add(new DatabaseField()
                {
                    Name = "_RecorderTRef",
                    Length = 4,
                    TypeName = "binary",
                    Scale = 0,
                    Precision = 0,
                    IsNullable = false,
                    KeyOrdinal = 0,
                    IsPrimaryKey = true,
                    Purpose = FieldPurpose.TypeCode
                });
            }

            // Устанавливаем признак множественного типа значения (составного типа данных)
            property.PropertyType.ReferenceTypeCode = 0; // multiple type value
            property.PropertyType.ReferenceTypeUuid = Guid.Empty; // multiple type value
        }
        public void ConfigureRegistersToPost(Document document, ConfigObject registers)
        {
            int registersCount = registers.GetInt32(new[] { 1 }); // количество регистров
            if (registersCount == 0) return;
            
            //int offset = 2;
            for (int r = 0; r < registersCount; r++)
            {
                // R.2.1 - uuid файла регистра
                //Guid fileName = registers.GetUuid(new[] { r + offset, 2, 1 });
                foreach (var collection in InfoBase.Registers)
                {
                    if (collection.TryGetValue(document.FullKey, out ApplicationObject register))
                    {
                        ConfigurePropertyРегистратор(register, document);
                        break;
                    }
                }
            }
        }

        #endregion

        #region "Publication system properties"

        public void ConfigurePropertyНомерОтправленного(Publication publication)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "НомерОтправленного",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_SentNo"
            };
            property.PropertyType.CanBeNumeric = true;
            property.PropertyType.NumericScale = 0;
            property.PropertyType.NumericPrecision = 10;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 9,
                Scale = 0,
                Precision = 10,
                TypeName = "numeric"
            });
            publication.Properties.Add(property);
        }
        public void ConfigurePropertyНомерПринятого(Publication publication)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "НомерПринятого",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_ReceivedNo"
            };
            property.PropertyType.CanBeNumeric = true;
            property.PropertyType.NumericScale = 0;
            property.PropertyType.NumericPrecision = 10;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 9,
                Scale = 0,
                Precision = 10,
                TypeName = "numeric"
            });
            publication.Properties.Add(property);
        }

        #endregion

        #region "Enumeration system properties"

        public void ConfigurePropertyПорядок(Enumeration enumeration)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Порядок",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_EnumOrder"
            };
            property.PropertyType.CanBeNumeric = true;
            property.PropertyType.NumericScale = 0;
            property.PropertyType.NumericPrecision = 10;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 9,
                Scale = 0,
                Precision = 10,
                TypeName = "numeric"
            });
            enumeration.Properties.Add(property);
        }

        #endregion

        #region "Information register system properties"

        public void ConfigurePropertyПериод(ApplicationObject register)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Период",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Period"
            };
            property.PropertyType.CanBeDateTime = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 6,
                Precision = 19,
                TypeName = "datetime2"
            });
            register.Properties.Add(property);
        }
        public void ConfigurePropertyНомерЗаписи(ApplicationObject register)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "НомерСтроки",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_LineNo"
            };
            property.PropertyType.CanBeNumeric = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 5,
                Precision = 9,
                TypeName = "numeric"
            });
            register.Properties.Add(property);
        }
        public void ConfigurePropertyАктивность(ApplicationObject register)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Активность",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Active"
            };
            property.PropertyType.CanBeBoolean = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 1,
                TypeName = "binary"
            });
            register.Properties.Add(property);
        }

        #endregion

        #region "Accumulation register system properties"

        public void ConfigurePropertyВидДвижения(AccumulationRegister register)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "ВидДвижения",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_RecordKind"
            };
            property.PropertyType.CanBeNumeric = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 5,
                Precision = 1,
                TypeName = "numeric"
            });
            register.Properties.Add(property);
        }
        public void ConfigurePropertyDimHash(AccumulationRegister register)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "DimHash",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_DimHash"
            };
            property.PropertyType.CanBeNumeric = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 9,
                Precision = 10,
                TypeName = "numeric"
            });
            register.Properties.Add(property);
        }

        #endregion

        #region "Accounts system properties"

        public void ConfigurePropertyПорядок(Account metaObject)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Порядок",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_OrderField"
            };
            property.PropertyType.CanBeString = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 7,
                TypeName = "nvarchar"
            });
            metaObject.Properties.Add(property);
        }

        public void ConfigurePropertyВид(Account metaObject)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Вид",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_Kind"
            };
            property.PropertyType.CanBeNumeric = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 1,
                Precision = 0,
                TypeName = "numeric"
            });
            metaObject.Properties.Add(property);
        }

        public void ConfigurePropertyЗабалансовый(Account metaObject)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "Забалансовый",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_OffBalance"
            };
            property.PropertyType.IsBinary = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 1,
                TypeName = "binary"
            });
            metaObject.Properties.Add(property);
        }

        #endregion

        #region "Accounting register system properties"

        public void ConfigurePropertyСчетДт(AccountingRegister register)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "СчетДт",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_AccountDtRRef"
            };
            property.PropertyType.IsBinary = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 16,
                TypeName = "binary"
            });
            register.Properties.Add(property);
        }

        public void ConfigurePropertyСчетКт(AccountingRegister register)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = "СчетКт",
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System,
                DbName = "_AccountCtRRef"
            };
            property.PropertyType.IsBinary = true;
            property.Fields.Add(new DatabaseField()
            {
                Name = property.DbName,
                Length = 16,
                TypeName = "binary"
            });
            register.Properties.Add(property);
        }

        #endregion

        #region "Predefined values (catalogs and characteristics)"

        public void ConfigurePredefinedValues(ApplicationObject metaObject)
        {
            if (!(metaObject is IPredefinedValues owner)) return;

            int predefinedValueUuid = 3;
            int predefinedIsFolder = 4;
            int predefinedValueName = 6;
            int predefinedValueCode = 7;
            int predefinedDescription = 8;

            string fileName = metaObject.FileName.ToString() + ".1c"; // файл с описанием предопределённых элементов
            if (metaObject is Characteristic)
            {
                fileName = metaObject.FileName.ToString() + ".7";
                predefinedValueName = 5;
                predefinedValueCode = 6;
                predefinedDescription = 7;
            }

            IReferenceCode codeInfo = (metaObject as IReferenceCode);

            ConfigObject configObject = FileReader.ReadConfigObject(fileName);

            if (configObject == null) return;

            ConfigObject parentObject = configObject.GetObject(new[] { 1, 2, 14, 2 });

            //string RootName = parentObject.GetString(new int[] { 6, 1 }); // имя корня предопределённых элементов = "Элементы" (уровень 0)
            //string RootName = parentObject.GetString(new int[] { 5, 1 }); // имя корня предопределённых элементов = "Характеристики" (уровень 0)

            int propertiesCount = parentObject.GetInt32(new[] { 2 });
            int predefinedFlag = propertiesCount + 3;
            int childrenValues = propertiesCount + 4;

            int hasChildren = parentObject.GetInt32(new[] { predefinedFlag }); // флаг наличия предопределённых элементов
            if (hasChildren == 0) return;

            ConfigObject predefinedValues = parentObject.GetObject(new[] { childrenValues }); // коллекция описаний предопределённых элементов

            int valuesCount = predefinedValues.GetInt32(new[] { 1 }); // количество предопределённых элементов (уровень 1)

            if (valuesCount == 0) return;

            int valueOffset = 2;
            for (int v = 0; v < valuesCount; v++)
            {
                PredefinedValue pv = new PredefinedValue();

                ConfigObject predefinedValue = predefinedValues.GetObject(new[] { v + valueOffset });

                pv.Uuid = predefinedValue.GetUuid(new[] { predefinedValueUuid, 2, 1 });
                pv.Name = predefinedValue.GetString(new[] { predefinedValueName, 1 });
                pv.IsFolder = (predefinedValue.GetInt32(new[] { predefinedIsFolder, 1 }) == 1);
                pv.Description = predefinedValue.GetString(new[] { predefinedDescription, 1 });

                if (codeInfo != null && codeInfo.CodeLength > 0)
                {
                    pv.Code = predefinedValue.GetString(new[] { predefinedValueCode, 1 });
                }

                owner.PredefinedValues.Add(pv);

                int haveChildren = predefinedValue.GetInt32(new[] { 9 }); // флаг наличия дочерних предопределённых элементов (0 - нет, 1 - есть)
                if (haveChildren == 1)
                {
                    ConfigObject children = predefinedValue.GetObject(new[] { 10 }); // коллекция описаний дочерних предопределённых элементов

                    ConfigurePredefinedValue(children, pv, metaObject);
                }
            }
        }
        private void ConfigurePredefinedValue(ConfigObject predefinedValues, PredefinedValue parent, ApplicationObject owner)
        {
            int valuesCount = predefinedValues.GetInt32(new[] { 1 }); // количество предопределённых элементов (уровень N)

            if (valuesCount == 0) return;

            int predefinedValueUuid = 3;
            int predefinedIsFolder = 4;
            int predefinedValueName = 6;
            int predefinedValueCode = 7;
            int predefinedDescription = 8;

            if (owner is Characteristic)
            {
                predefinedValueName = 5;
                predefinedValueCode = 6;
                predefinedDescription = 7;
            }

            IReferenceCode codeInfo = (owner as IReferenceCode);

            int valueOffset = 2;
            for (int v = 0; v < valuesCount; v++)
            {
                PredefinedValue pv = new PredefinedValue();

                ConfigObject predefinedValue = predefinedValues.GetObject(new[] { v + valueOffset });

                pv.Uuid = predefinedValue.GetUuid(new[] { predefinedValueUuid, 2, 1 });
                pv.Name = predefinedValue.GetString(new[] { predefinedValueName, 1 });
                pv.IsFolder = (predefinedValue.GetInt32(new[] { predefinedIsFolder, 1 }) == 1);
                pv.Description = predefinedValue.GetString(new[] { predefinedDescription, 1 });

                if (codeInfo != null && codeInfo.CodeLength > 0)
                {
                    pv.Code = predefinedValue.GetString(new[] { predefinedValueCode, 1 });
                }

                parent.Children.Add(pv);

                int haveChildren = predefinedValue.GetInt32(new[] { 9 }); // флаг наличия дочерних предопределённых элементов (0 - нет, 1 - есть)
                if (haveChildren == 1)
                {
                    ConfigObject children = predefinedValue.GetObject(new[] { 10 }); // коллекция описаний дочерних предопределённых элементов

                    ConfigurePredefinedValue(children, pv, owner);
                }
            }
        }

        #endregion
    }
}