unit Delphi.Serialization.RttiTypeResolver;

interface

uses
  System.Rtti,
  Delphi.Serialization,
  Spring.Collections;

type
  TRttiTypeResolver = class(TInterfacedObject, ITypeResolver)
  strict protected
    function HasSameSerialVersionUID(const AType: TRttiInstanceType; const ASerialVersionUID: String): boolean;
    function CreateNewInstance(const AType: TRttiInstanceType): TValue;
    procedure InitializeRttiTypeCache;
    function HasSerialVersionUID(const AType: TRttiInstanceType; out OSerialVersionUID: String): Boolean;
    function IsRttiInstanceType(const AType: TRttiType; out OInstanceType: TRttiInstanceType): boolean;
  strict protected
    class var FRttiContext: TRttiContext;
    class var FRttiTypeCache: IDictionary<string, TRttiInstanceType>;
    class var FCacheAlreadyBuild: boolean;
    class constructor Create;
  public
    constructor Create;
    function Resolve(const ASerialVersionUID, AReference: String): TValue;
    function ResolveType(const ASerialVersionUID: String): TRttiInstanceType;
  end;

implementation

uses
  DSharp.Core.Reflection,
  Spring,
  System.SysUtils,
  Spring.Reflection.Activator;

constructor TRttiTypeResolver.Create;
begin
  if not FCacheAlreadyBuild then
    InitializeRttiTypeCache;
end;

class constructor TRttiTypeResolver.Create;
begin
  FRttiContext := TRttiContext.Create;
  FRttiTypeCache := TCollections.CreateDictionary<string, TRttiInstanceType>;
  FCacheAlreadyBuild := false;
end;

procedure TRttiTypeResolver.InitializeRttiTypeCache;
var
  LType: TRttiType;
  LInstanceType: TRttiInstanceType;
  LSVUID: String;
begin
  for LType in FRttiContext.GetTypes do
  begin
    if not IsRttiInstanceType(LType, LInstanceType) then
      Continue;
    if not HasSerialVersionUID(LInstanceType, LSVUID) then
      Continue;

    FRttiTypeCache.Add(LSVUID, LInstanceType);
  end;

  FCacheAlreadyBuild := true;
end;

function TRttiTypeResolver.Resolve(
  const ASerialVersionUID: String;
  const AReference: String): TValue;
var
  LType: TRttiInstanceType;
begin
  LType := ResolveType(ASerialVersionUID);
  Result := CreateNewInstance(LType);
end;

function TRttiTypeResolver.ResolveType(const ASerialVersionUID: String): TRttiInstanceType;
var
  LType: TRttiType;
  LInstanceType: TRttiInstanceType;
begin
  Result := NIL;

  if not FRttiTypeCache.TryGetValue(ASerialVersionUID, Result) then
    Guard.RaiseArgumentException('Resolving failed, missing Registration for Type with SVUID: ' + ASerialVersionUID);
end;

function TRttiTypeResolver.HasSerialVersionUID(
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

function TRttiTypeResolver.CreateNewInstance(const AType: TRttiInstanceType): TValue;
begin
  Result := TActivator.CreateInstance(AType);
end;

function TRttiTypeResolver.HasSameSerialVersionUID(
  const AType: TRttiInstanceType;
  const ASerialVersionUID: String): boolean;
var
  LSVUIDToCompare: String;
begin
  if not HasSerialVersionUID(AType, LSVUIDToCompare) then
    Exit(false);

  Result := SameText(LSVUIDToCompare, ASerialVersionUID);
end;

function TRttiTypeResolver.IsRttiInstanceType(
  const AType: TRttiType;
  out OInstanceType: TRttiInstanceType): boolean;
begin
  Result := AType.IsInstance;
  if not Result then
    Exit;

  OInstanceType := AType AS TRttiInstanceType;
end;

end.
