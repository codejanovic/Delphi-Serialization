unit Delphi.Serialization.Tests.Testdata.SimpleObject;

interface

uses
  Spring.Collections,
  Delphi.Serialization,
  Delphi.Serialization.Tests.Testdata;

type
  //TODO: Error on invalid Serialversionuid (none/dup)
  [Element('Addressdata')]
  [SerialVersionUID('{75076476-709A-4371-9DBC-2AAD1A4CA73B}')]
  TAddress = class(TObject)
  strict protected
    FName: string;
    FStreet: string;
    FPostalCode: Integer;
    FCity: String;
    FCountry: string;
  protected
    function GetName: string;
    function GetStreet: string;
    function GetPostalCode: Integer;
    function GetCity: String;
    function GetCountry: string;

    procedure SetName(const AValue: string);
    procedure SetStreet(const AValue: string);
    procedure SetPostalCode(const AValue: Integer);
    procedure SetCity(const AValue: String);
    procedure SetCountry(const AValue: string);

  public
    [Element('ContactPerson')]
    property Name: string read GetName write SetName;
    property Street: string read GetStreet write SetStreet;
    [Element('Zipcode')]
    property PostalCode: Integer read GetPostalCode write SetPostalCode;
    property City: String read GetCity write SetCity;
    property Country: string read GetCountry write SetCountry;
  end;

  [Element('Customerdata')]
  [SerialVersionUID('{65DF7B79-4016-41EB-8BA1-45AD5855B39A}')]
  TCustomer = class(TObject)
  strict protected
    FFirstName: string;
    FLastName: string;
    FCustomerId: Integer;
    FDefaultAddress: IAddress;
    FRegistrationDate: TDateTime;

  protected
    function GetFirstName: string;
    function GetLastName: string;
    function GetCustomerId: Integer;
    function GetDefaultAddress: IAddress;
    function GetHasDefaultAddress: boolean;
    function GetRegistrationDate: TDateTime;

    procedure SetFirstName(const AValue: string);
    procedure SetLastName(const AValue: string);
    procedure SetCustomerId(const AValue: Integer);
    procedure SetDefaultAddress(const AValue: IAddress);
    procedure SetRegistrationDate(const AValue: TDateTime);

  public
    property FirstName: string read GetFirstName write SetFirstName;
    property LastName: string read GetLastName write SetLastName;
    property CustomerId: Integer read GetCustomerId write SetCustomerId;
    property DefaultAddress: IAddress read GetDefaultAddress write SetDefaultAddress;
    [Transient]
    property HasDefaultAddress: boolean read GetHasDefaultAddress;
    property RegistrationDate: TDateTime read GetRegistrationDate write SetRegistrationDate;
  end;

  TObjectWithoutSerialVersionUID = class(TObject)

  end;

implementation

uses
  System.SysUtils;

{ TCustomer }

function TCustomer.GetCustomerId: Integer;
begin
  Result := FCustomerId;
end;

function TCustomer.GetDefaultAddress: IAddress;
begin
  Result := FDefaultAddress;
end;

function TCustomer.GetFirstName: string;
begin
  Result := FFirstName;
end;

function TCustomer.GetHasDefaultAddress: boolean;
begin
  Result := Assigned(FDefaultAddress);
end;

function TCustomer.GetLastName: string;
begin
  Result := FLastName;
end;

function TCustomer.GetRegistrationDate: TDateTime;
begin
  Result := FRegistrationDate;
end;

procedure TCustomer.SetCustomerId(const AValue: Integer);
begin
  FCustomerId := AValue;
end;

procedure TCustomer.SetDefaultAddress(const AValue: IAddress);
begin
  FDefaultAddress := AValue;
end;

procedure TCustomer.SetFirstName(const AValue: string);
begin
  FFirstName := AValue;
end;

procedure TCustomer.SetLastName(const AValue: string);
begin
  FLastName := AValue;
end;

procedure TCustomer.SetRegistrationDate(const AValue: TDateTime);
begin
  FRegistrationDate := AValue;
end;

{ TAddress }

function TAddress.GetCity: String;
begin
  Result := FCity;
end;

function TAddress.GetCountry: string;
begin
  Result := FCountry;
end;

function TAddress.GetName: string;
begin
  Result := FName;
end;

function TAddress.GetPostalCode: Integer;
begin
  Result := FPostalCode;
end;

function TAddress.GetStreet: string;
begin
  Result := FStreet;
end;

procedure TAddress.SetCity(const AValue: String);
begin
  FCity := AValue;
end;

procedure TAddress.SetCountry(const AValue: string);
begin
  FCountry := AValue;
end;

procedure TAddress.SetName(const AValue: string);
begin
  FName := AValue;
end;

procedure TAddress.SetPostalCode(const AValue: Integer);
begin
  FPostalCode := AValue;
end;

procedure TAddress.SetStreet(const AValue: string);
begin
  FStreet := AValue;
end;

end.
