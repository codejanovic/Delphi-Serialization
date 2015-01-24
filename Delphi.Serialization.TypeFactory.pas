unit Delphi.Serialization.TypeFactory;

interface

uses
  System.Rtti,
  Delphi.Serialization,
  Spring.Collections;

type
  TSerialVersionUID = String;
  TTypeReference = string;

  TTypeFactory = class(TInterfacedObject, ITypeResolver, ITypeRegistrator)
  strict protected
    FRttiFallbackTypeResolver: ITypeResolver;
    FTypeDictionary: IDictionary<TSerialVersionUID, TRttiInstanceType>;
    FTypeInstanceDictionary: IDictionary<TTypeReference, TValue>;

    procedure InternalRegisterType(const ASerialVersionUID: String; const AValue: TRttiInstanceType); overload;
    procedure InternalRegisterType(const AValue: TRttiInstanceType); overload;
    procedure InternalRegisterInstanceOfType(const AReference: String; var AInstance: TValue);

    function HasSerialVersionUID(const AType: TRttiInstanceType; out OSerialVersionUID: String): Boolean;
    function IsTypeAlreadyInstantiated(const ATypeReference: string; out OValue: TValue): boolean;
    function TryGetRegisteredType(const ASerialVersionUID: String; out OValue: TRttiInstanceType): boolean;
    function TryGetStandardConstructor(const AType: TRttiInstanceType; out OValue: TRttiMethod): boolean;
    function CreateNewInstance(const AType: TRttiInstanceType): TValue;
  public
    constructor Create(const ARttiFallbackTypeResolver: ITypeResolver);
  public
    function Resolve(const ASerialVersionUID, AReference: String): TValue;
    function ResolveType(const ASerialVersionUID: String): TRttiInstanceType;

    procedure RegisterType(const ASerialVersionUID: String; const AValue: TRttiInstanceType); overload;
    procedure RegisterType(const AValue: TRttiInstanceType); overload;
  end;

implementation

uses
  DSharp.Core.Reflection,
  Spring,
  Spring.Reflection.Activator, System.SysUtils;

{ TTypeResolver }

constructor TTypeFactory.Create(const ARttiFallbackTypeResolver: ITypeResolver);
begin
  Guard.CheckNotNull(ARttiFallbackTypeResolver, 'RttiTypeResolver missing');

  FRttiFallbackTypeResolver := ARttiFallbackTypeResolver;
  FTypeDictionary := TCollections.CreateDictionary<TSerialVersionUID, TRttiInstanceType>;
  FTypeInstanceDictionary := TCollections.CreateDictionary<TTypeReference, TValue>;
end;

function TTypeFactory.Resolve(
  const ASerialVersionUID: String;
  const AReference: String): TValue;
var
  LInstance: TValue;
  LType: TRttiInstanceType;
begin
  if IsTypeAlreadyInstantiated(AReference, LInstance) then
    Exit(LInstance);

  LType := ResolveType(ASerialVersionUID);
  LInstance := CreateNewInstance(LType);
  InternalRegisterInstanceOfType(AReference, LInstance);

  Result := LInstance;
end;

function TTypeFactory.ResolveType(const ASerialVersionUID: String): TRttiInstanceType;
begin
  if not TryGetRegisteredType(ASerialVersionUID, Result) then
    Result := FRttiFallbackTypeResolver.ResolveType(ASerialVersionUID);
end;

procedure TTypeFactory.RegisterType(const AValue: TRttiInstanceType);
begin
  InternalRegisterType(AValue);
end;

procedure TTypeFactory.RegisterType(
  const ASerialVersionUID: String;
  const AValue: TRttiInstanceType);
begin
  InternalRegisterType(ASerialVersionUID, AValue);
end;

function TTypeFactory.HasSerialVersionUID(
  const AType: TRttiInstanceType;
  out OSerialVersionUID: String): Boolean;
var
  LSVUID: SerialVersionUIDAttribute;
  LHasSVUID: boolean;
begin
  LHasSVUID := AType.TryGetCustomAttribute<SerialVersionUIDAttribute>(LSVUID);
  if LHasSVUID then
    OSerialVersionUID := LSVUID.SerialVersionUID;

  Result := LHasSVUID;
end;

procedure TTypeFactory.InternalRegisterType(
  const ASerialVersionUID: String;
  const AValue: TRttiInstanceType);
begin
  FTypeDictionary.Add(ASerialVersionUID, AValue);
end;

procedure TTypeFactory.InternalRegisterType(const AValue: TRttiInstanceType);
var
  LSVUID: String;
begin
  if not HasSerialVersionUID(AValue, LSVUID) then
    Guard.RaiseArgumentException('Registration failed, missing SerialVersionUID for Type: ' + AValue.QualifiedName);

  InternalRegisterType(LSVUID, AValue);
end;

function TTypeFactory.IsTypeAlreadyInstantiated(const ATypeReference: string;
  out OValue: TValue): boolean;
begin
  Result := FTypeInstanceDictionary.TryGetValue(ATypeReference, OValue);
end;

function TTypeFactory.TryGetRegisteredType(
  const ASerialVersionUID: String;
  out OValue: TRttiInstanceType): boolean;
begin
  Result := FTypeDictionary.TryGetValue(ASerialVersionUID, OValue);
end;

function TTypeFactory.TryGetStandardConstructor(
  const AType: TRttiInstanceType;
  out OValue: TRttiMethod): boolean;
begin
  Result := AType.TryGetStandardConstructor(OValue);
end;

function TTypeFactory.CreateNewInstance(const AType: TRttiInstanceType): TValue;
begin
  Result := TActivator.CreateInstance(AType);
end;

procedure TTypeFactory.InternalRegisterInstanceOfType(
  const AReference: String;
  var AInstance: TValue);
begin
  FTypeInstanceDictionary.Add(AReference, AInstance);
end;

end.
