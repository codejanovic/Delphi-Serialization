unit Delphi.Serialization.Tests.TypeFactory.UseCases;

interface

uses
  Delphi.Serialization;

type
  ITypeResolverUseCase = interface
    function GetName: String;
    procedure SetName(const AValue: String);

    property Name: String read GetName write SetName;
  end;

  INoSerialVersionUID = interface(ITypeResolverUseCase)
  end;

  TNoSerialVersionUID = class(TObject)
  protected
    FName: String;
    function GetName: String;
    procedure SetName(const AValue: String);
  public
    property Name: String read GetName write SetName;
  end;

  TInterfacedNoSerialVersionUID = class(TInterfacedObject, INoSerialVersionUID)
  protected
    FName: String;
    function GetName: String;
    procedure SetName(const AValue: String);
  public
    property Name: String read GetName write SetName;
  end;

  TObjectWithCustomConstructor = class(TObject)
  strict protected
    FName: String;

  public
    constructor Create(const AName: String); overload;
    property Name: String read FName write FName;
  end;

  [SerialVersionUID('{98E9CD98-94E1-4734-95E4-2A0C127AF3B8}')]
  TObjectWithSerialVersionUID = class(TObject)
  end;

implementation

{ TNoSerialVersionUID }

function TNoSerialVersionUID.GetName: String;
begin
  Result := FName;
end;

procedure TNoSerialVersionUID.SetName(const AValue: String);
begin
  FName := AValue;
end;

{ TInterfacedNoSerialVersionUID }

function TInterfacedNoSerialVersionUID.GetName: String;
begin
  Result := FName;
end;

procedure TInterfacedNoSerialVersionUID.SetName(const AValue: String);
begin
  FName := AValue;
end;

{ TCustomConstructor }

constructor TObjectWithCustomConstructor.Create(const AName: String);
begin
  FName := AName;
end;


end.
