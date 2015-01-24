unit Delphi.Serialization.Tests.TypeFactory;

interface
uses
  DUnitX.TestFramework,
  Delphi.Serialization, System.Rtti;

type

  [TestFixture]
  TTestTypeFactory = class(TObject)
  strict protected
    function GetRttiType<T>: TRttiType;
    procedure TryRegisterType(const ASerialVersionUID: String; const AType: TRttiType); overload;
    procedure TryRegisterType(const AType: TRttiType); overload;
  public
    FTypeFactory: ITypeRegistrator;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestRegisterTwoTypesWithSameSerialVersionUID_WillFail;
    [Test]
    procedure TestRegisterRttiTypeWithoutSerialVersionUID_WillFail;
    [Test]
    [TestCase('Test1','{7ECC375C-9F3B-4C0B-9262-E22FE9F2B815}, 0000, 1111')]
    procedure TestResolveRegisteredTypeTwoTimesAndIsSameReference(const ASerialVersionUID: String; const AReference: String; const AAnotherReference: String);
    [Test]
    [TestCase('Test1','{3C567783-D553-45CA-930E-E8ED09C66F1F}')]
    procedure TestResolveRegisteredType(const ASerialVersionUID: String);
    [Test]
    [TestCase('Test1','{B08A7F4C-BA2D-4A8A-A860-9CEC2DB7A3D0}, 0000')]
    procedure TestResolveUnregisteredType_WithoutSerialVersionUID_WillFail(const ASerialVersionUID: String; const AReference: String);
    [Test]
    [TestCase('Test1','{98E9CD98-94E1-4734-95E4-2A0C127AF3B8}, 0000')]
    procedure TestResolveUnregisteredType_WithSerialVersionUID(const ASerialVersionUID: String; const AReference: String);
    [Test]
    [TestCase('Test1','{55E86286-5596-4A8D-B5DE-605D0371DE94}')]
    procedure TestRegisterRttiTypeWithoutSerialVersionUIDAndAddCustomSerialVersionUID(const ASerialVersionUID: String);
    [Test]
    [TestCase('Test1','{60C42038-7AB8-4273-9264-2A23C1D8E4AE}')]
    procedure TestRegisterTypeWithCustomConstructor_CustomConstructorWillNotBeCalled(const ASerialVersionUID: String);
    [Test]
    procedure TestPerformance;
  end;

implementation

uses
  Delphi.Serialization.TypeFactory,
  DSharp.Core.Reflection,
  System.SysUtils,
  Spring,
  Delphi.Serialization.Tests.TypeFactory.UseCases,
  Spring.Reflection,
  Delphi.Serialization.RttiTypeResolver;

procedure TTestTypeFactory.Setup;
var
  LRttiTypeResolver: ITypeResolver;
begin
  LRttiTypeResolver := TRttiTypeResolver.Create;
  FTypeFactory := TTypeFactory.Create(LRttiTypeResolver);
end;

procedure TTestTypeFactory.TearDown;
begin

end;

procedure TTestTypeFactory.TestRegisterTwoTypesWithSameSerialVersionUID_WillFail;
var
  LType: TRttiType;
  LAnotherType: TRttiType;
const
  LSVUID = '{79EA8FEA-74B8-4A26-8166-914ED5B9E33B}';
begin
  LType := GetRttiType<TNoSerialVersionUID>;
  LAnotherType := GetRttiType<TInterfacedNoSerialVersionUID>;

  Assert.WillNotRaiseAny(
  procedure
  begin
    TryRegisterType(LSVUID, LType);
  end
  );

  Assert.WillRaise(
  procedure
  begin
    TryRegisterType(LSVUID, LType);
  end,
  EListError
  );

  Assert.WillRaise(
  procedure
  begin
    TryRegisterType(LSVUID, LAnotherType);
  end,
  EListError
  );

end;

procedure TTestTypeFactory.TestRegisterRttiTypeWithoutSerialVersionUID_WillFail;
var
  LType: TRttiType;
begin
  LType := GetRttiType<TNoSerialVersionUID>;

  Assert.WillRaise(
  procedure
  begin
    TryRegisterType(LType);
  end,
  EArgumentException
  );
end;


function TTestTypeFactory.GetRttiType<T>: TRttiType;
begin
  Result := TType.GetType(TypeInfo(T));
end;

procedure TTestTypeFactory.TryRegisterType(const ASerialVersionUID: String;
  const AType: TRttiType);
begin
  FTypeFactory.RegisterType(ASerialVersionUID, TRttiInstanceType(AType));
end;

procedure TTestTypeFactory.TryRegisterType(const AType: TRttiType);
begin
  FTypeFactory.RegisterType(TRttiInstanceType(AType));
end;

procedure TTestTypeFactory.TestResolveRegisteredTypeTwoTimesAndIsSameReference(
    const ASerialVersionUID: String;
    const AReference: String;
    const AAnotherReference: String);
var
  LType: TRttiType;
  LTypeInstanceOne: TValue;
  LTypeInstanceSameAsOne: TValue;
  LTypeInstanceDifferentAsOne: TValue;
  LTypeObjectOne: TNoSerialVersionUID;
  LTypeObjectSameAsOne: TNoSerialVersionUID;
  LTypeObjectDifferentAsOne: TNoSerialVersionUID;
const
  LObjectName = 'I am the expected Object';
begin
  LType := GetRttiType<TNoSerialVersionUID>;
  TryRegisterType(ASerialVersionUID, LType);

  // Same Reference
  LTypeInstanceOne := FTypeFactory.Resolve(ASerialVersionUID, AReference);
  Assert.IsTrue(LTypeInstanceOne.AsObject is TNoSerialVersionUID, 'Reslolving failed');

  LTypeObjectOne :=  LTypeInstanceOne.AsObject AS TNoSerialVersionUID;
  Assert.AreNotEqual(LTypeObjectOne.Name, LObjectName);
  LTypeObjectOne.Name := LObjectName;

  // Same Reference
  LTypeInstanceSameAsOne := FTypeFactory.Resolve(ASerialVersionUID, AReference);
  Assert.IsTrue(LTypeInstanceSameAsOne.AsObject is TNoSerialVersionUID, 'Reslolving failed');

  LTypeObjectSameAsOne :=  LTypeInstanceOne.AsObject AS TNoSerialVersionUID;
  Assert.IsTrue(LTypeObjectOne = LTypeObjectSameAsOne);
  Assert.AreEqual(LTypeObjectSameAsOne.Name, LObjectName);

  //Resolving same Type, but different Reference
  LTypeInstanceDifferentAsOne := FTypeFactory.Resolve(ASerialVersionUID, AAnotherReference);
  Assert.IsTrue(LTypeInstanceDifferentAsOne.AsObject is TNoSerialVersionUID, 'Reslolving failed');

  LTypeObjectDifferentAsOne := LTypeInstanceDifferentAsOne.AsObject AS TNoSerialVersionUID;
  Assert.AreNotEqual(LTypeObjectDifferentAsOne.Name, LObjectName);
  Assert.IsFalse(LTypeObjectDifferentAsOne = LTypeObjectSameAsOne);
end;

procedure TTestTypeFactory.TestResolveUnregisteredType_WithoutSerialVersionUID_WillFail(const ASerialVersionUID: String; const AReference: String);
var
  LTypeInstanceOne: TValue;
begin
  Assert.WillRaise(
  procedure
  begin
    LTypeInstanceOne := FTypeFactory.Resolve(ASerialVersionUID, AReference);
  end,
  EArgumentException
  );
end;

procedure TTestTypeFactory.TestRegisterRttiTypeWithoutSerialVersionUIDAndAddCustomSerialVersionUID(const ASerialVersionUID: String);
var
  LType: TRttiType;
begin
  LType := GetRttiType<TNoSerialVersionUID>;
  TryRegisterType(ASerialVersionUID, LType);
end;

procedure TTestTypeFactory.TestResolveRegisteredType(const ASerialVersionUID: String);
var
  LType: TRttiType;
  LTypeInstanceOne: TValue;
begin
  LType := GetRttiType<TNoSerialVersionUID>;
  TryRegisterType(ASerialVersionUID, LType);

  LTypeInstanceOne := FTypeFactory.Resolve(ASerialVersionUID, 'Not relevant');
  Assert.IsTrue(LTypeInstanceOne.AsObject is TNoSerialVersionUID, 'Reslolving failed');
end;

procedure TTestTypeFactory.TestRegisterTypeWithCustomConstructor_CustomConstructorWillNotBeCalled(const ASerialVersionUID: String);
var
  LType: TRttiType;
  LTypeInstanceOne: TValue;
  LTypeObjectOne: TObjectWithCustomConstructor;
begin
  LType := GetRttiType<TObjectWithCustomConstructor>;
  TryRegisterType(ASerialVersionUID, LType);

  LTypeInstanceOne := FTypeFactory.Resolve(ASerialVersionUID, 'Not relevant');
  LTypeObjectOne := TObjectWithCustomConstructor(LTypeInstanceOne.AsObject);
  Assert.IsTrue(LTypeObjectOne.Name.IsEmpty);
end;

procedure TTestTypeFactory.TestResolveUnregisteredType_WithSerialVersionUID(
  const ASerialVersionUID, AReference: String);
var
  LTypeInstanceOne: TValue;
begin
  Assert.WillNotRaiseAny(
  procedure
  begin
    LTypeInstanceOne := FTypeFactory.Resolve(ASerialVersionUID, AReference);
  end
  );

  Assert.IsTrue(LTypeInstanceOne.AsObject is TObjectWithSerialVersionUID);
end;

procedure TTestTypeFactory.TestPerformance;
var
  LResolver: ITypeResolver;
  i: Integer;
begin
  LResolver := TRttiTypeResolver.Create;

  for i := 1 to 1000 do
    LResolver.ResolveType('{98E9CD98-94E1-4734-95E4-2A0C127AF3B8}');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTypeFactory);
end.
