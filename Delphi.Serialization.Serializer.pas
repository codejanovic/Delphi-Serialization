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
unit Delphi.Serialization.Serializer;

interface

uses
  System.Rtti,
  Delphi.Serialization;

type
  //TODO: save reference info
  TSerializer<T> = class(TInterfacedObject, ISerializer<T>)
  strict protected
    FFormatWriter: ISerializationFormatWriter;

    procedure WritePrimitive(const AValue: TValue; const AElementName: string);
    procedure WriteEnumerable(const AValue: TValue);
    procedure WriteEvent(const AValue: TValue);
    procedure WriteObject(const AValue: TValue); overload;
    procedure WriteObject(const AValue: TValue; const AElementName: String); overload;
    procedure WriteObjectStart(const AValue: TValue; const AElementName: String);
    procedure WriteObjectEnd(const AValue: TValue; const AElementName: String);
    procedure WriteSerialVersionUID(const AValue: TValue);
    procedure WriteValue(const AValue: TValue; const AElementName: String);

    function GetObjectElementName(const AValue: TValue; const AElementName: string = ''): String;
    function GetSerialVersionUID(const AValue: TValue): String;

    function IsIgnored(const AValue: TRttiProperty): boolean; overload;
    function IsIgnored(const AValue: TRttiField): boolean; overload;

    function IsValid(const AProperty: TRttiProperty; const AValue: TValue): boolean; overload;
    function IsValid(const AField: TRttiField; const AValue: TValue): boolean; overload;

    function IsIgnoredByVisibility(const AValue: TRttiProperty): boolean; overload;
    function IsIgnoredByVisibility(const AValue: TRttiField): boolean; overload;

    function IsIgnoredByAttribute(const AValue: TRttiProperty): boolean; overload;
    function IsIgnoredByAttribute(const AValue: TRttiField): boolean; overload;

    function IsIgnoredByBaseImpl(const AValue: TRttiProperty): boolean;
    function IsInstanceProperty(const AValue: TRttiProperty): boolean;
    function IsOrdinalType(const AValue: TRttiProperty): boolean;
    function IsInstanceType(const AValue: TRttiProperty): boolean; overload;
    function IsInstanceType(const AValue: TRttiField): boolean; overload;
    function DoesInstancePropertyDefaultDiffersFromValuesOrdinal(const AProperty: TRttiProperty; const
       AValue: TValue): boolean;
  public
    constructor Create(const AFormatWriter: ISerializationFormatWriter);
    procedure Serialize(const AValue: T);
  end;

implementation

uses
  System.SysUtils,
  DSharp.Core.Reflection,
  System.TypInfo,
  Spring,
  Delphi.Serialization.ExceptionHelper;

procedure TSerializer<T>.Serialize(const AValue: T);
var
  genericValue: TValue;
begin
  genericValue := TValue.From<T>(AValue);
  WriteValue(genericValue, '');
end;

constructor TSerializer<T>.Create(const AFormatWriter: ISerializationFormatWriter);
begin
  Guard.CheckNotNull(AFormatWriter, 'SerializationFormatWriter');
  FFormatWriter := AFormatWriter;
end;

function TSerializer<T>.DoesInstancePropertyDefaultDiffersFromValuesOrdinal(
  const AProperty: TRttiProperty;
  const AValue: TValue): boolean;
begin
  Result := TRttiInstanceProperty(AProperty).Default <> AValue.AsOrdinal;
end;

function TSerializer<T>.GetObjectElementName(const AValue: TValue; const AElementName: string): String;
var
  LObject: TObject;
  LElementAttribute: ElementEntityAttribute;
begin
  if not AElementName.IsEmpty then
    Exit(AElementName);

  LObject := AValue.AsObject;
  if LObject.GetType.TryGetCustomAttribute<ElementEntityAttribute>(LElementAttribute) then
    Exit(LElementAttribute.ElementName);

  // Fallback
  Result := LObject.ClassName;
end;

function TSerializer<T>.GetSerialVersionUID(const AValue: TValue): String;
var
  LObject: TObject;
  LSerialVersionUIDAttribute: SerialVersionUIDAttribute;
begin
  Result := '';
  LObject := AValue.AsObject;
  if LObject.GetType.TryGetCustomAttribute<SerialVersionUIDAttribute>(LSerialVersionUIDAttribute) then
    Exit(LSerialVersionUIDAttribute.SerialVersionUID);
end;

function TSerializer<T>.IsIgnored(const AValue: TRttiProperty): boolean;
begin
  Result := IsIgnoredByAttribute(AValue)
            or IsIgnoredByVisibility(AValue)
            or IsIgnoredByBaseImpl(AValue);
end;

function TSerializer<T>.IsIgnored(const AValue: TRttiField): boolean;
begin
  Result := IsIgnoredByAttribute(AValue)
            or IsIgnoredByVisibility(AValue);
end;

function TSerializer<T>.IsIgnoredByAttribute(const AValue: TRttiProperty): boolean;
begin
  Result := AValue.IsDefined<TransientEntityAttribute>;
end;

function TSerializer<T>.IsIgnoredByAttribute(const AValue: TRttiField): boolean;
begin
  Result := AValue.IsDefined<TransientEntityAttribute>;
end;

function TSerializer<T>.IsIgnoredByBaseImpl(const AValue: TRttiProperty): boolean;
begin
  Result := SameText(AValue.Name, 'RefCount');
end;

function TSerializer<T>.IsIgnoredByVisibility(const AValue: TRttiField): boolean;
begin
  Result := not (AValue.Visibility in [mvPublic, mvPublished]);
end;

function TSerializer<T>.IsValid(const AProperty: TRttiProperty; const AValue: TValue): boolean;
begin
  Result := not IsInstanceProperty(AProperty)
            or (not IsOrdinalType(AProperty))
            or (IsOrdinalType(AProperty) and DoesInstancePropertyDefaultDiffersFromValuesOrdinal(AProperty, AValue) )
            or (IsInstanceProperty(AProperty) and not AValue.IsEmpty);
end;

function TSerializer<T>.IsIgnoredByVisibility(const AValue: TRttiProperty): boolean;
begin
  Result := not (AValue.Visibility in [mvPublic, mvPublished]);
end;

function TSerializer<T>.IsInstanceProperty(const AValue: TRttiProperty): boolean;
begin
  Result := AValue is TRttiInstanceProperty;
end;

function TSerializer<T>.IsInstanceType(const AValue: TRttiField): boolean;
begin
  Result := AValue.FieldType.IsInstance;
end;

function TSerializer<T>.IsInstanceType(const AValue: TRttiProperty): boolean;
begin
  Result := AValue.PropertyType.IsInstance;
end;

function TSerializer<T>.IsOrdinalType(const AValue: TRttiProperty): boolean;
begin
  Result := AValue.PropertyType.IsOrdinal;
end;

function TSerializer<T>.IsValid(const AField: TRttiField; const AValue: TValue): boolean;
begin
  Result := IsInstanceType(AField)
            and (not AValue.IsEmpty);
end;

procedure TSerializer<T>.WriteEnumerable(const AValue: TValue);
var
  LObject: TObject;
  LEnumerator: TValue;
  LMethod: TRttiMethod;
  LProperty: TRttiProperty;
  LValue: TValue;
  LType: TRttiType;
  LFreeEnumerator: Boolean;
begin
  LObject := AValue.AsObject;
  if LObject.HasMethod('Add') and LObject.TryGetMethod('GetEnumerator', LMethod) then
  begin
    LEnumerator := LMethod.Invoke(LObject, []);
    LFreeEnumerator := LEnumerator.IsObject;
    try

      LType := LEnumerator.RttiType;
      if LType is TRttiInterfaceType then
      begin
        LEnumerator := LEnumerator.ToObject;
        LType := LEnumerator.RttiType;
      end;
      if LType.TryGetMethod('MoveNext', LMethod)
        and LType.TryGetProperty('Current', LProperty) then
      begin
        while LMethod.Invoke(LEnumerator, []).AsBoolean do
        begin
          LValue := LProperty.GetValue(LEnumerator.AsPointer);
          WriteValue(LValue, LProperty.PropertyType.Name);
        end;
      end;
    finally
      if LFreeEnumerator then
        LEnumerator.AsObject.Free();
    end;
  end;
end;

procedure TSerializer<T>.WriteEvent(const AValue: TValue);
var
  LEvent: PMethod;
  LMethod: TRttiMethod;
begin
  LEvent := AValue.GetReferenceToRawData();
  if TObject(LEvent.Data).TryGetMethod(LEvent.Code, LMethod) then
  begin
    FFormatWriter.WriteNodeValueOfCurrentNode(LMethod.Name);
  end;
end;

procedure TSerializer<T>.WriteObject(const AValue: TValue);
begin
  WriteObject(AValue, '');
end;

procedure TSerializer<T>.WriteObject(const AValue: TValue; const AElementName: String);
var
  LObject: TObject;
  LProperty: TRttiProperty;
  LValue: TValue;
  LAttribute: ElementEntityAttribute;
  LField: TRttiField;
begin
  LObject := AValue.AsObject;
  if not Assigned(LObject) then
    exit;

  WriteObjectStart(AValue, AElementName);

  for LProperty in LObject.GetProperties() do
  begin
    if IsIgnored(LProperty) then
      Continue;
    if not LProperty.TryGetValue(LObject, LValue) then
      Continue;
    if not IsValid(LProperty, LValue) then
      Continue;

    if LProperty.TryGetCustomAttribute<ElementEntityAttribute>(LAttribute) then
      WriteValue(LValue, LAttribute.ElementName)
    else
      WriteValue(LValue, LProperty.Name);
  end;

  for LField in LObject.GetType.GetFields do
  begin
    if IsIgnored(LField) then
      Continue;
    if not LField.TryGetValue(LObject, LValue) then
      Continue;
    if not IsValid(LField, LValue) then
      Continue;

    if LField.TryGetCustomAttribute<ElementEntityAttribute>(LAttribute) then
      WriteValue(LValue, LAttribute.ElementName)
    else
      WriteValue(LValue, LField.Name);
  end;

  WriteEnumerable(AValue);

  WriteObjectEnd(AValue, AElementName);
end;

procedure TSerializer<T>.WriteObjectEnd(const AValue: TValue; const AElementName: String);
begin
  FFormatWriter.WriteEndElement(GetObjectElementName(AValue, AElementName));
end;

procedure TSerializer<T>.WriteObjectStart(const AValue: TValue; const AElementName: String);
var
  objectElementName: String;
begin
  objectElementName := GetObjectElementName(AValue, AElementName);
  FFormatWriter.WriteStartElement(objectElementName);
  WriteSerialVersionUID(AValue);
end;

procedure TSerializer<T>.WritePrimitive(const AValue: TValue; const AElementName: string);
begin
  FFormatWriter.WriteStartElement(AElementName);
  FFormatWriter.WriteNodeValueOfCurrentNode(AValue);
  FFormatWriter.WriteEndElement(AElementName);
end;

procedure TSerializer<T>.WriteSerialVersionUID(const AValue: TValue);
begin
  FFormatWriter.WriteNodeAttributeOfCurrentNode(ATTRIBUTE_SERIALVERSIONUID, GetSerialVersionUID(AValue));
end;

procedure TSerializer<T>.WriteValue(const AValue: TValue; const AElementName: String);
begin
  case AValue.Kind of
    tkInteger,
    tkInt64,
    tkChar,
    tkString,
    tkWChar,
    tkLString,
    tkWString,
    tkUString,
    tkEnumeration,
    tkFloat,
    tkSet:
      WritePrimitive(AValue, AElementName);
    tkClass:
      WriteObject(AValue, AElementName);
    tkMethod:
      WriteEvent(AValue);
    tkInterface:
      WriteObject(TValue.From<TObject>( AValue.AsInterface AS TObject ), AElementName);
    else
      Guard.RaiseSerializationTypeNotSupportedException(AValue);
  end;
end;

end.
