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

unit Delphi.Serialization.XmlReader;

interface

uses
  XMLIntf,
  Delphi.Serialization,
  System.Classes,
  System.SysUtils,
  System.Rtti;

type

  TXmlReader = class(TInterfacedObject, ISerializationFormatReader)
  strict protected
    FCurrentNode: IXMLNode;
    FDocument: IXMLDocument;
    FIndex: Integer;
    FXmlValueConverter: ISerializationFormatPrimitiveValueConverter;

    function ReadXmlStringFromStream(const AValue: TStream): String;
    procedure SetupXmlDocumentFromInput(const AInput: TStream);

  public
    constructor Create(const AXmlInput: TStream; const AXmlValueConverter: ISerializationFormatPrimitiveValueConverter);

    function IsStartElement(): Boolean; overload;
    function IsStartElement(const AName: string): Boolean; overload;

    procedure ReadStartElement; overload;
    procedure ReadStartElement(const AName: string); overload;
    procedure ReadEndElement; overload;

    procedure ReadCurrentNodeValue(var AValue: TValue); overload;
    function ReadCurrentNodeValue: String; overload;
    procedure ReadCurrentNodeAttributeValue(const AAttribute: String; var AValue: TValue); overload;
    function ReadCurrentNodeAttributeValue(const AAttribute: string): string; overload;
    function ReadCurrentNodeName: String;
  end;

implementation

uses
  XMLDoc,
  XSBuiltIns,
  System.IOUtils,
  Spring;

{ TXmlReader }

constructor TXmlReader.Create(const AXmlInput: TStream; const AXmlValueConverter: ISerializationFormatPrimitiveValueConverter);
begin
  Guard.CheckNotNull(AXmlInput, 'XmlInputStream');
  Guard.CheckNotNull(AXmlValueConverter, 'XmlValueConverter');

  FXmlValueConverter := AXmlValueConverter;
  SetupXmlDocumentFromInput(AXmlInput);
end;

function TXmlReader.IsStartElement: Boolean;
begin
  if Assigned(FCurrentNode) then
    Result := FCurrentNode.ChildNodes.Count > FIndex
  else
    Result := Assigned(FDocument.DocumentElement);
end;

function TXmlReader.IsStartElement(const AName: string): Boolean;
begin
  if Assigned(FCurrentNode) then
    Result := (FCurrentNode.ChildNodes.Count > FIndex)
      and SameText(FCurrentNode.ChildNodes[FIndex].NodeName, AName)
  else
    Result := SameText(FDocument.DocumentElement.NodeName, AName);
end;

procedure TXmlReader.ReadCurrentNodeAttributeValue(const AAttribute: String; var AValue: TValue);
var
  attributeValue: String;
begin
  attributeValue := ReadCurrentNodeAttributeValue(AAttribute);
  FXmlValueConverter.StringToValue(attributeValue, AValue);
end;

function TXmlReader.ReadCurrentNodeAttributeValue(const AAttribute: string): string;
begin
  Result := FCurrentNode.Attributes[AAttribute];
end;

function TXmlReader.ReadCurrentNodeName: String;
begin
  Result := FCurrentNode.NodeName;
end;

function TXmlReader.ReadCurrentNodeValue: String;
begin
  Result := FCurrentNode.NodeValue;
end;

procedure TXmlReader.ReadCurrentNodeValue(var AValue: TValue);
begin
  FXmlValueConverter.StringToValue(FCurrentNode.NodeValue, AValue);
end;

procedure TXmlReader.ReadEndElement;
begin
  FIndex := FCurrentNode.ParentNode.ChildNodes.IndexOf(FCurrentNode) + 1;
  FCurrentNode := FCurrentNode.ParentNode;
end;

procedure TXmlReader.ReadStartElement;
begin
  if Assigned(FCurrentNode) then
    FCurrentNode := FCurrentNode.ChildNodes[FIndex]
  else
    FCurrentNode := FDocument.DocumentElement;

  FIndex := 0;
end;

procedure TXmlReader.ReadStartElement(const AName: string);
begin
  if IsStartElement(AName) then
    ReadStartElement()
  else
    raise EDeserializerError.CreateFmt('Element "%s" not found', [AName]);
end;


function TXmlReader.ReadXmlStringFromStream(const AValue: TStream): String;
var
  LStreamReader: TStreamReader;
begin
  LStreamReader := TStreamReader.Create(AValue);
  try
    AValue.Position := 0;
    Result := LStreamReader.ReadToEnd;
  finally
    FreeAndNil(LStreamReader);
  end;
end;

procedure TXmlReader.SetupXmlDocumentFromInput(const AInput: TStream);
begin
  FDocument := TXMLDocument.Create(nil);
  FDocument.XML.Text := ReadXmlStringFromStream(AInput);
  FDocument.Active := True;
  FCurrentNode := nil;
  FIndex := 0;
end;

end.
