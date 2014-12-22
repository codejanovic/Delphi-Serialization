unit Delphi.Serialization.Tests.Main;

interface
uses
  DUnitX.TestFramework;

type
  TObjectConstraint = class of TObject;

  [TestFixture]
  TMainTests = class(TObject)
  private
    function GetFilePathToTestFile(const AFileName: string): string;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure TestSerializeSimpleInterfacedObject;
    [Test]
    procedure TestDeserializeSimpleInterfacedObject;
  end;

implementation

uses
  System.Classes,
  Delphi.Serialization.Tests.Testdata.SimpleInterfacedObject,
  Delphi.Serialization,
  System.SysUtils,
  Vcl.Forms,
  System.IOUtils, Delphi.Serialization.Tests.Testdata, Spring.Container,
  System.Rtti;

function TMainTests.GetFilePathToTestFile(const AFileName: string): string;
var
  appPath: String;
  testoutputPath: String;
  testfilepath: String;
  s: TStream;
const
  testoutputDirName = 'testoutput';
begin
  appPath := ExtractFilePath(Application.ExeName);
  testoutputPath := IncludeTrailingPathDelimiter(appPath) + '..\..\' + testoutputDirName;

  ForceDirectories(testoutputPath);

  testfilepath := IncludeTrailingPathDelimiter(testoutputPath) + AFileName;
  if not TFile.Exists(testfilepath) then
  begin
    s := TFile.Create(testfilepath, fmCreate);
    FreeAndNil(s);
  end;

  Result := testfilepath;
end;

procedure TMainTests.Setup;
begin
end;

procedure TMainTests.TestDeserializeSimpleInterfacedObject;
var
  LInput: TStringStream;
  LCustomer: ICustomer;
  LSerializationFacade: TSerializationFacade;
begin
  LInput := TStringStream.Create;
  LSerializationFacade := TSerializationFacade.Create;
  try
    LInput.WriteString('<?xml version="1.0"?>');
    LInput.WriteString('<Customerdata serialVersionUID="{5BA74FD6-D930-41BE-956D-61CDA59305A4}">');
    LInput.WriteString('<FirstName>John</FirstName>');
    LInput.WriteString('<LastName>Doe</LastName>');
    LInput.WriteString('<CustomerId>5</CustomerId>');
    LInput.WriteString('<DefaultAddress serialVersionUID="{3D4E2CC7-B7CE-4235-A7D2-86CDB6A69080}">');
    LInput.WriteString('<ContactPerson>John Doe Ltd.</ContactPerson>');
    LInput.WriteString('<Street>Tea Berry Lane 540</Street>');
    LInput.WriteString('<Zipcode>54143</Zipcode>');
    LInput.WriteString('<City>Marinette</City>');
    LInput.WriteString('<Country>Wisconsin</Country>');
    LInput.WriteString('</DefaultAddress>');
    LInput.WriteString('<RegistrationDate>1899-12-30T00:00:00.000+01:00</RegistrationDate>');
    LInput.WriteString('</Customerdata>');

    LCustomer := TCustomer.Create;
    LSerializationFacade.DeSerialize<ICustomer>(LCustomer, LInput);

    Assert.AreEqual(LCustomer.FirstName, TSerializationTestdata.DEFAULT_CUSTOMER_FIRSTNAME);
    Assert.AreEqual(LCustomer.LastName, TSerializationTestdata.DEFAULT_CUSTOMER_LASTNAME);
    Assert.AreEqual(LCustomer.CustomerId, TSerializationTestdata.DEFAULT_CUSTOMER_CUSTOMERID);
    Assert.AreEqual(LCustomer.HasDefaultAddress, false);
    Assert.AreEqual(LCustomer.DefaultAddress.Name, TSerializationTestdata.DEFAULT_ADDRESS_NAME);
    Assert.AreEqual(LCustomer.DefaultAddress.Street, TSerializationTestdata.DEFAULT_ADDRESS_STREET);
    Assert.AreEqual(LCustomer.DefaultAddress.PostalCode, TSerializationTestdata.DEFAULT_ADDRESS_POSTALCODE);
    Assert.AreEqual(LCustomer.DefaultAddress.City, TSerializationTestdata.DEFAULT_ADDRESS_CITY);
    Assert.AreEqual(LCustomer.DefaultAddress.Country, TSerializationTestdata.DEFAULT_ADDRESS_COUNTRY);
  finally
    FreeAndNil(LInput);
    FreeAndNil(LSerializationFacade);
  end;
end;

procedure TMainTests.TestSerializeSimpleInterfacedObject;
var
  LCustomer: ICustomer;
  LAddress: IAddress;
  LSerializationFacade: TSerializationFacade;
  LOutputAddress,
  LOutputCustomer: TStringStream;
begin
  LCustomer := TSerializationTestdata.CreateDefaultCustomer;
  LAddress := TSerializationTestdata.CreateDefaultAddress;

  LSerializationFacade := TSerializationFacade.Create;
  try
    LOutputAddress := TStringStream.Create;
    LOutputCustomer := TStringStream.Create;

    LSerializationFacade.Serialize<IAddress>(LAddress, LOutputAddress);
    LSerializationFacade.Serialize<ICustomer>(LCustomer, LOutputCustomer);

    TFile.WriteAllText(GetFilePathToTestFile('serialize_interfacedobject_IAddress.xml'), LOutputAddress.DataString);
    TFile.WriteAllText(GetFilePathToTestFile('serialize_interfacedobject_ICustomer.xml'), LOutputCustomer.DataString);
  finally
    FreeAndNil(LSerializationFacade);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TMainTests);
end.
