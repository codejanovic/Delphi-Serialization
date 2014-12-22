(*
  Copyright (c) 2011-2012, Stefan Glienke
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  - Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  - Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  - Neither the name of this library nor the names of its contributors may be
    used to endorse or promote products derived from this software without
    specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
*)

unit Delphi.Serialization;

interface

uses
  SysUtils,
  Rtti,
  System.Classes;

CONST
  ATTRIBUTE_SERIALVERSIONUID = 'serialVersionUID';

type
  EDeserializerError = class(Exception);
  ESerializerError = class(Exception);
  EPrimitiveValueNotSupportedError = class(Exception);
  ESerializationTypeNotSupportedError = class(Exception);

  {$REGION 'Attributes'}
  TransientAttribute = class(TCustomAttribute)
  end;
  //TODO: Error on invalid names (eg with whitespaces)
  ElementAttribute = class(TCustomAttribute)
  private
    FElementName: string;
  public
    constructor Create(const AElementName: string);

    property ElementName: string read FElementName;
  end;

  SerialVersionUIDAttribute = class(TCustomAttribute)
  private
    FSerialVersionUID: string;
  public
    constructor Create(const ASerialVersionUID: string);

    property SerialVersionUID: string read FSerialVersionUID;
  end;
  {$ENDREGION}

  ISerializationFormatPrimitiveValueConverter = interface
    ['{BA828678-28AC-4E16-92BF-CD004FF29A4C}']
    function ValueToString(const AValue: TValue): string;
    procedure StringToValue(const AStringValue: String; var AValue: TValue);
  end;

  ISerializationFormatReader = interface
  ['{3A056ED3-0CB6-4E64-BCFF-FE22765BBDB2}']
    function IsStartElement: Boolean; overload;
    function IsStartElement(const AName: string): Boolean; overload;

    procedure ReadStartElement; overload;
    procedure ReadStartElement(const AName: string); overload;
    procedure ReadEndElement;

    procedure ReadCurrentNodeValue(var AValue: TValue); overload;
    function ReadCurrentNodeValue: String; overload;
    procedure ReadCurrentNodeAttributeValue(const AAttribute: String; var AValue: TValue); overload;
    function ReadCurrentNodeAttributeValue(const AAttribute: string): string; overload;
    function ReadCurrentNodeName: String;
  end;

  ISerializationFormatWriter = interface
    ['{A0974478-0769-41E8-9D71-16A05BC3835E}']
    procedure WriteStartElement(const AName: string);
    procedure WriteEndElement(const AName: string);

    procedure WriteNodeValueOfCurrentNode(const AValue: TValue); overload;
    procedure WriteNodeAttributeOfCurrentNode(const AAttributeName: String; const AAttributeValue: TValue);
  end;

  //TODO: logger needed?
  ISerializer<T> = interface
    procedure Serialize(const AValue: T);
  end;

  IDeserializer<T> = interface
    procedure Deserialize(const AValue: T);
  end;

  //TODO: access to default instance of each component
  //TODO: more flexibel facade
  TSerializationFacade = class
  strict protected
    function CreateDefaultValueConverter: ISerializationFormatPrimitiveValueConverter;
    function CreateDefaultFormatWriter(const AOutput: TStream; const AValueConverter: ISerializationFormatPrimitiveValueConverter): ISerializationFormatWriter;
    function CreateDefaultSerializer<T>(const AFormatWriter: ISerializationFormatWriter): ISerializer<T>;
    function CreateDefaultFormatReader(const AInput: TStream; const AValueConverter: ISerializationFormatPrimitiveValueConverter): ISerializationFormatReader;
    function CreateDefaultDeserializer<T>(const AFormatReader: ISerializationFormatReader): IDeserializer<T>;
  public
    constructor Create;

    procedure Serialize<T>(const AValue: T; const AOutput: TStream); overload;
    procedure Serialize<T>(const AValue: T; const ACustomFormatWriter: ISerializationFormatWriter); overload;
    procedure Serialize<T>(const AValue: T; const ACustomSerializer: ISerializer<T>); overload;

    procedure DeSerialize<T>(const AValue: T; const AInput: TStream); overload;
    procedure DeSerialize<T>(const AValue: T; const ACustomFormatReader: ISerializationFormatReader); overload;
    procedure DeSerialize<T>(const AValue: T; const ACustomDeserializer: IDeSerializer<T>); overload;
  end;

  //TODO: SerializationException Object

implementation

uses
  Delphi.Serialization.XmlValueConverter, Delphi.Serialization.XmlWriter,
  Delphi.Serialization.XmlReader, Delphi.Serialization.Serializer, Delphi.Serialization.Deserializer;

{ XmlElementAttribute }

constructor ElementAttribute.Create(const AElementName: string);
begin
  FElementName := AElementName;
end;

{ XmlSerialVersionUID }

constructor SerialVersionUIDAttribute.Create(const ASerialVersionUID: string);
begin
  FSerialVersionUID := ASerialVersionUID;
end;

{ TSerializationFacade<T> }

constructor TSerializationFacade.Create;
begin

end;

procedure TSerializationFacade.Deserialize<T>(const AValue: T; const AInput: TStream);
var
  LDefaultValueConverter: ISerializationFormatPrimitiveValueConverter;
  LDefaultFormatReader: ISerializationFormatReader;
  LDefaultDeserializer: IDeserializer<T>;
begin
  LDefaultValueConverter := CreateDefaultValueConverter;
  LDefaultFormatReader := CreateDefaultFormatReader(AInput, LDefaultValueConverter);
  LDefaultDeserializer := CreateDefaultDeserializer<T>(LDefaultFormatReader);
  LDefaultDeserializer.Deserialize(AValue);
end;

procedure TSerializationFacade.Deserialize<T>(
  const AValue: T;
  const ACustomFormatReader: ISerializationFormatReader);
var
  LDefaultDeserializer: IDeserializer<T>;
begin
  LDefaultDeserializer := CreateDefaultDeserializer<T>(ACustomFormatReader);
  LDefaultDeserializer.Deserialize(AValue);
end;

function TSerializationFacade.CreateDefaultDeserializer<T>(
  const AFormatReader: ISerializationFormatReader): IDeserializer<T>;
begin
  Result := TDeserializer<T>.Create(AFormatReader);
end;

function TSerializationFacade.CreateDefaultFormatReader(
  const AInput: TStream;
  const AValueConverter: ISerializationFormatPrimitiveValueConverter): ISerializationFormatReader;
begin
  Result := TXmlReader.Create(AInput, AValueConverter);
end;

function TSerializationFacade.CreateDefaultFormatWriter(
  const AOutput: TStream;
  const AValueConverter: ISerializationFormatPrimitiveValueConverter): ISerializationFormatWriter;
begin
  Result := TXmlWriter.Create(AOutput, CreateDefaultValueConverter);
end;

function TSerializationFacade.CreateDefaultSerializer<T>(const AFormatWriter: ISerializationFormatWriter): ISerializer<T>;
begin
  Result := TSerializer<T>.Create(AFormatWriter);
end;

function TSerializationFacade.CreateDefaultValueConverter: ISerializationFormatPrimitiveValueConverter;
begin
  Result := TXmlPrimitiveValueConverter.Create;
end;

procedure TSerializationFacade.DeSerialize<T>(
  const AValue: T;
  const ACustomDeserializer: IDeSerializer<T>);
begin

end;

procedure TSerializationFacade.Serialize<T>(
  const AValue: T;
  const AOutput: TStream);
var
  LDefaultValueConverter: ISerializationFormatPrimitiveValueConverter;
  LDefaultFormatWriter: ISerializationFormatWriter;
  LDefaultSerializer: ISerializer<T>;
begin
  LDefaultValueConverter := CreateDefaultValueConverter;
  LDefaultFormatWriter := CreateDefaultFormatWriter(AOutput, LDefaultValueConverter);
  LDefaultSerializer := CreateDefaultSerializer<T>(LDefaultFormatWriter);

  LDefaultSerializer.Serialize(AValue);
end;

procedure TSerializationFacade.Serialize<T>(
  const AValue: T;
  const ACustomFormatWriter: ISerializationFormatWriter);
var
  LDefaultSerializer: ISerializer<T>;
begin
  LDefaultSerializer := CreateDefaultSerializer<T>(ACustomFormatWriter);
  LDefaultSerializer.Serialize(AValue);
end;

procedure TSerializationFacade.Serialize<T>(
  const AValue: T;
  const ACustomSerializer: ISerializer<T>);
begin
  ACustomSerializer.Serialize(AValue);
end;

end.
