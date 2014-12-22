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

unit Delphi.Serialization.XmlWriter;

interface

uses
  Delphi.Serialization,
  XMLIntf,
  System.Classes,
  System.SysUtils,
  System.Rtti;

type
  TXmlWriter = class(TInterfacedObject, ISerializationFormatWriter)
  strict protected
    FCurrentNode: IXMLNode;
    FDocument: IXMLDocument;
    FOutputStream: TStream;
    FStringStream: TStringStream;
    FXmlValueConverter: ISerializationFormatPrimitiveValueConverter;

    procedure FixQCReport108838;
    procedure UpdateOutputStream;
    procedure SetupXmlDocument;

  public
    constructor Create(const AOutput: TStream; const AXmlValueConverter: ISerializationFormatPrimitiveValueConverter);
    destructor Destroy; override;

    procedure WriteStartElement(const AName: string);
    procedure WriteEndElement(const AName: string);
    procedure WriteNodeValueOfCurrentNode(const AValue: TValue);
    procedure WriteNodeAttributeOfCurrentNode(const AAttributeName: String; const AAttributeValue: TValue);
  end;


implementation

uses
  XmlDoc,
  System.Win.ComObj,
  Spring;

{ TXmlWriter }


constructor TXmlWriter.Create(
  const AOutput: TStream;
  const AXmlValueConverter: ISerializationFormatPrimitiveValueConverter);
begin
  Guard.CheckNotNull(AOutput, 'XmlOutputStream');
  Guard.CheckNotNull(AXmlValueConverter, 'XmlValueConverter');

  FStringStream := TStringStream.Create;
  FOutputStream := AOutput;
  FXmlValueConverter := AXmlValueConverter;
  SetupXmlDocument;
end;

destructor TXmlWriter.Destroy;
begin
  FreeAndNil(FStringStream);
  inherited;
end;

procedure TXmlWriter.FixQCReport108838;
begin
  // http://qc.embarcadero.com/wc/qcmain.aspx?d=108838
  CoInitializeEx(nil, 0);
end;

procedure TXmlWriter.SetupXmlDocument;
begin
  FixQCReport108838;

  FDocument := TXMLDocument.Create(nil);
  FDocument.Options := FDocument.Options + [doNodeAutoIndent];
  FDocument.Active := True;
  FDocument.Encoding := 'utf-8';
  FDocument.Version := '1.0';
end;

procedure TXmlWriter.UpdateOutputStream;
begin
  //TODO: performance?
  FStringStream.Clear;
  FStringStream.WriteString(FDocument.XML.Text);

  FStringStream.Position := 0;
  FOutputStream.Position := 0;
  FOutputStream.CopyFrom(FStringStream, FStringStream.Size);
end;

procedure TXmlWriter.WriteEndElement(const AName: string);
var
  LCurrentNode: IXMLNode;
begin
  if not SameText(FCurrentNode.NodeName, AName) then
    Exit;

  LCurrentNode := FCurrentNode;
  FCurrentNode := LCurrentNode.ParentNode;
  if not LCurrentNode.HasChildNodes then
    FCurrentNode.ChildNodes.Remove(LCurrentNode);

  UpdateOutputStream;
end;

procedure TXmlWriter.WriteNodeAttributeOfCurrentNode(
  const AAttributeName: String;
  const AAttributeValue: TValue);
begin
  FCurrentNode.Attributes[AAttributeName] := FXmlValueConverter.ValueToString(AAttributeValue);
  UpdateOutputStream;
end;

procedure TXmlWriter.WriteNodeValueOfCurrentNode(const AValue: TValue);
begin
  FCurrentNode.NodeValue := FXmlValueConverter.ValueToString(AValue);
  UpdateOutputStream;
end;

procedure TXmlWriter.WriteStartElement(const AName: string);
begin
  if Assigned(FCurrentNode) then
    FCurrentNode := FCurrentNode.AddChild(AName)
  else
    FCurrentNode := FDocument.AddChild(AName);

  UpdateOutputStream;
end;


end.
