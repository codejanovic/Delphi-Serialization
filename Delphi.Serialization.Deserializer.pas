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
unit Delphi.Serialization.Deserializer;

interface

uses
  Delphi.Serialization,
  System.Rtti;

type
  //TODO: restore based on reference info
  //TODO: restore based on serialVersionUID
  TDeserializer<T> = class(TInterfacedObject, IDeserializer<T>)
  strict protected
    FRoot: TObject;
    FFormatReader: ISerializationFormatReader;

    procedure CreateObject(var AValue: TValue);
    procedure ReadEnumerable(var AValue: TValue);
    procedure ReadEvent(var AValue: TValue);
    procedure ReadObject(var AValue: TValue);
    procedure ReadValue(var AValue: TValue);

    function FindPropertyByElementName(AObject: TObject; const AElementName: string; out AProperty: TRttiProperty): Boolean;
    function FindFieldByElementName(AObject: TObject; const AElementName: string; out AField: TRttiField): Boolean;
    function FindTypeBySerialVersionUID(const ASerialVersionUID: string; out AType: TRttiType): Boolean;
  public
    constructor Create(const AFormatReader: ISerializationFormatReader);
    procedure Deserialize(const AValue: T);
  end;

implementation

uses
  System.TypInfo,
  System.SysUtils,
  DSharp.Core.Reflection,
  Spring,
  System.Variants, Delphi.Serialization.ExceptionHelper;


function TDeserializer<T>.FindPropertyByElementName(AObject: TObject;
    const AElementName: string; out AProperty: TRttiProperty): Boolean;
var
  LProperty: TRttiProperty;
  LAttribute: ElementAttribute;
begin
  Result := False;
  for LProperty in AObject.GetProperties do
  begin
    if LProperty.TryGetCustomAttribute<ElementAttribute>(LAttribute)
      and SameText(LAttribute.ElementName, AElementName) then
    begin
      AProperty := LProperty;
      Result := True;
      Break;
    end;
  end;
end;

function TDeserializer<T>.FindTypeBySerialVersionUID(
  const ASerialVersionUID: string;
  out AType: TRttiType): Boolean;
var
  LType: TRttiType;
  LSerialVersionUIDAttribute: SerialVersionUIDAttribute;
  Context: TRttiContext;
begin
  //TODO: changeable registration (spring container?)
  //TODO: caching
  Context := TRttiContext.Create;

  for LType in Context.GetTypes do
  begin
    if not LType.IsInstance then
      Continue;
    if not LType.TryGetCustomAttribute<SerialVersionUIDAttribute>(LSerialVersionUIDAttribute) then
      Continue;
    if not SameText(LSerialVersionUIDAttribute.SerialVersionUID, ASerialVersionUID) then
      Continue;

      AType := LType;
      Break;
  end;

  Result := Assigned(AType);
end;

function TDeserializer<T>.FindFieldByElementName(AObject: TObject;
  const AElementName: string; out AField: TRttiField): Boolean;
var
  LField: TRttiField;
  LAttribute: ElementAttribute;
begin
  Result := False;
  for LField in AObject.GetFields do
  begin
    if LField.TryGetCustomAttribute<ElementAttribute>(LAttribute)
      and SameText(LAttribute.ElementName, AElementName) then
    begin
      AField := LField;
      Result := True;
      Break;
    end;
  end;
end;


procedure TDeserializer<T>.Deserialize(const AValue: T);
var
  LValue: TValue;
begin
  LValue := TValue.From<T>(AValue);
  FFormatReader.ReadStartElement;
  ReadValue(LValue);
  FFormatReader.ReadEndElement;
end;

procedure TDeserializer<T>.CreateObject(var AValue: TValue);
var
  LType: TRttiType;
  LMethod: TRttiMethod;
  LArgs: TArray<TValue>;
  LSVUID: String;
begin
  LSVUID := FFormatReader.ReadCurrentNodeAttributeValue(ATTRIBUTE_SERIALVERSIONUID);

  if FindTypeBySerialVersionUID(LSVUID, LType)
    and LType.TryGetStandardConstructor(LMethod) then
  begin
    SetLength(LArgs, LMethod.ParameterCount);
    AValue := LMethod.Invoke(LType.AsInstance.MetaclassType, LArgs);
    if not Assigned(FRoot) then
    begin
      FRoot := AValue.AsObject();
    end;
  end;
end;

procedure TDeserializer<T>.ReadEnumerable(var AValue: TValue);
var
  LObject: TObject;
  LType: TRttiType;
  LMethod: TRttiMethod;
  LValue: TValue;
begin
  LObject := AValue.AsObject;

  if LObject.TryGetMethod('Clear', LMethod) then
  begin
    LMethod.Invoke(LObject, []);
  end;

  if LObject.HasMethod('GetEnumerator')
    and LObject.TryGetMethod('Add', LMethod) then
  begin
    LType := LMethod.GetParameters[0].ParamType;
    while FFormatReader.IsStartElement(LType.Name) do
    begin
      FFormatReader.ReadStartElement();

      TValue.Make(nil, LType.Handle, LValue);
      ReadValue(LValue);
      LMethod.Invoke(AValue, [LValue]);

      FFormatReader.ReadEndElement();
    end;
  end;
end;

procedure TDeserializer<T>.ReadEvent(var AValue: TValue);
var
  LEvent: PMethod;
  LMethod: TRttiMethod;
begin
  LEvent := AValue.GetReferenceToRawData();
  if FRoot.TryGetMethod(VarToStrDef(FFormatReader.ReadCurrentNodeValue, ''), LMethod) then
  begin
    LEvent.Data := FRoot;
    LEvent.Code := LMethod.CodeAddress;
  end;
end;

procedure TDeserializer<T>.ReadObject(var AValue: TValue);
var
  LObject: TObject;
  LProperty: TRttiProperty;
  LValue: TValue;
  LField: TRttiField;
begin
  ReadEnumerable(AValue);

  LObject := AValue.AsObject;
  while FFormatReader.IsStartElement do
  begin
    FFormatReader.ReadStartElement();

    if (LObject.TryGetProperty(FFormatReader.ReadCurrentNodeName, LProperty)
      or FindPropertyByElementName(LObject, FFormatReader.ReadCurrentNodeName, LProperty))
      and (LProperty.IsWritable or LProperty.PropertyType.IsInstance) then
    begin
      LValue := LProperty.GetValue(LObject);
      ReadValue(LValue);
      if not LProperty.PropertyType.IsInstance then
      begin
        LProperty.SetValue(LObject, LValue);
      end;
    end
    else
    if LObject.TryGetField(FFormatReader.ReadCurrentNodeName, LField)
      or FindFieldByElementName(LObject, FFormatReader.ReadCurrentNodeName, LField) then
    begin
      LValue := LField.GetValue(LObject);
      ReadValue(LValue);
      if not LField.FieldType.IsInstance then
      begin
        LField.SetValue(LObject, LValue);
      end;
    end;

    FFormatReader.ReadEndElement();
  end;
end;


procedure TDeserializer<T>.ReadValue(var AValue: TValue);
var
  intfValue: TValue;
begin
  if AValue.IsEmpty then
  begin
    CreateObject(AValue);
  end;

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
      FFormatReader.ReadCurrentNodeValue(AValue);
    tkClass:
      ReadObject(AValue);
    tkInterface:
    begin
      intfValue := TValue.From<TObject>( AValue.AsInterface AS TObject );
      ReadObject(intfValue);
    end;
    tkMethod:
      ReadEvent(AValue);
    else
      Guard.RaiseSerializationTypeNotSupportedException(AValue);
  end;
end;

constructor TDeserializer<T>.Create(const AFormatReader: ISerializationFormatReader);
begin
  Guard.CheckNotNull(AFormatReader, 'SerializationFormatReader');
  FFormatReader := AFormatReader;
end;

end.
