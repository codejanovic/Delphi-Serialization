unit Delphi.Serialization.Tests.Testdata;

interface

type
  IAddress = interface
    ['{67FD8DEF-C55F-4AA8-BB19-29E405017AC0}']
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

    property Name: string read GetName write SetName;
    property Street: string read GetStreet write SetStreet;
    property PostalCode: Integer read GetPostalCode write SetPostalCode;
    property City: String read GetCity write SetCity;
    property Country: string read GetCountry write SetCountry;
  end;

  ICustomer = interface
    ['{646593F7-FE37-4F85-87BF-BCC599C11BAB}']
    function GetFirstName: string;
    function GetLastName: string;
    function GetCustomerId: Integer;
    function GetDefaultAddress: IAddress;
    function GetRegistrationDate: TDateTime;
    function GetHasDefaultAddress: boolean;

    procedure SetFirstName(const AValue: string);
    procedure SetLastName(const AValue: string);
    procedure SetCustomerId(const AValue: Integer);
    procedure SetDefaultAddress(const AValue: IAddress);
    procedure SetRegistrationDate(const AValue: TDateTime);

    property FirstName: string read GetFirstName write SetFirstName;
    property LastName: string read GetLastName write SetLastName;
    property CustomerId: Integer read GetCustomerId write SetCustomerId;
    property DefaultAddress: IAddress read GetDefaultAddress write SetDefaultAddress;
    property HasDefaultAddress: boolean read GetHasDefaultAddress;
    property RegistrationDate: TDateTime read GetRegistrationDate write SetRegistrationDate;
  end;

  TSerializationTestdata = class abstract
  public const
    DEFAULT_CUSTOMER_FIRSTNAME = 'John';
    DEFAULT_CUSTOMER_LASTNAME = 'Doe';
    DEFAULT_CUSTOMER_CUSTOMERID = 5;
    DEFAULT_CUSTOMER_REGISTRATIONDATE = 0;
    DEFAULT_ADDRESS_NAME = 'John Doe Ltd.';
    DEFAULT_ADDRESS_STREET = 'Tea Berry Lane 540';
    DEFAULT_ADDRESS_POSTALCODE = 54143;
    DEFAULT_ADDRESS_CITY = 'Marinette';
    DEFAULT_ADDRESS_COUNTRY = 'Wisconsin';
  public
    class function CreateDefaultCustomer: ICustomer;
    class function CreateDefaultAddress: IAddress;
  end;

implementation

uses
  Delphi.Serialization.Tests.Testdata.SimpleInterfacedObject;

{ TSerializationTestdata }

class function TSerializationTestdata.CreateDefaultAddress: IAddress;
begin
  Result := TAddress.Create;
  Result.Name := DEFAULT_ADDRESS_NAME;
  Result.Street := DEFAULT_ADDRESS_STREET;
  Result.PostalCode := DEFAULT_ADDRESS_POSTALCODE;
  Result.City := DEFAULT_ADDRESS_CITY;
  Result.Country := DEFAULT_ADDRESS_COUNTRY;
end;

class function TSerializationTestdata.CreateDefaultCustomer: ICustomer;
begin
  Result := TCustomer.Create;
  Result.FirstName := DEFAULT_CUSTOMER_FIRSTNAME;
  Result.LastName := DEFAULT_CUSTOMER_LASTNAME;
  Result.CustomerId := DEFAULT_CUSTOMER_CUSTOMERID;
  Result.DefaultAddress := CreateDefaultAddress;
  Result.RegistrationDate := DEFAULT_CUSTOMER_REGISTRATIONDATE;
end;

end.
