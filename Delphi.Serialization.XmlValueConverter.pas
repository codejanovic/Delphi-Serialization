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
unit Delphi.Serialization.XmlValueConverter;

interface

uses
  Delphi.Serialization,
  System.Rtti,
  System.SysUtils;

type
  TXmlPrimitiveValueConverter = class(TInterfacedObject, ISerializationFormatPrimitiveValueConverter)
  strict protected
    FDefaultFormatSettings: TFormatSettings;

    function ConvertDateToString(const AValue: TDate): string;
    function ConvertDateTimeToString(const AValue: TDateTime): string;
    function ConvertTimeToString(const AValue: TTime): String;
    function ConvertFloatToString(const AValue: Extended): string;

    function ConvertStringToDate(const AValue: String): TDate;
    function ConvertStringToDateTime(const AValue: String): TDateTime;
    function ConvertStringToTime(const AValue: String): TTime;
    function ConvertStringToFloat(const AValue: String): Extended;
  public
    constructor Create;

    function ValueToString(const AValue: TValue): string;
    procedure StringToValue(const AStringValue: String; var AValue: TValue);
  end;

implementation

uses
  Spring.SystemUtils,
  Soap.XSBuiltIns,
  System.Variants,
  System.TypInfo,
  DSharp.Core.Reflection,
  Delphi.Serialization.ExceptionHelper,
  Spring;

{ TXmlValueConverter }

function TXmlPrimitiveValueConverter.ConvertDateTimeToString(const AValue: TDateTime): string;
begin
  Result := DateTimeToXMLTime(AValue);
end;

function TXmlPrimitiveValueConverter.ConvertDateToString(const AValue: TDate): string;
begin
  Result := DateToStr(AValue, FDefaultFormatSettings);
end;

function TXmlPrimitiveValueConverter.ConvertFloatToString(const AValue: Extended): string;
begin
  Result := FloatToStr(AValue, FDefaultFormatSettings);
end;

function TXmlPrimitiveValueConverter.ConvertStringToDate(const AValue: String): TDate;
begin
  Result := StrToDate(AValue, FDefaultFormatSettings);
end;

function TXmlPrimitiveValueConverter.ConvertStringToDateTime(const AValue: String): TDateTime;
begin
  Result := XMLTimeToDateTime(AValue);
end;

function TXmlPrimitiveValueConverter.ConvertStringToFloat(const AValue: String): Extended;
begin
  Result := StrToFloat(AValue, FDefaultFormatSettings);
end;

function TXmlPrimitiveValueConverter.ConvertStringToTime(const AValue: String): TTime;
begin
  Result := Frac(XMLTimeToDateTime(FormatDateTime('yyyy-mm-dd''T', 0) + AValue));
end;

function TXmlPrimitiveValueConverter.ConvertTimeToString(const AValue: TTime): String;
begin
  Result := Copy(DateTimeToXMLTime(AValue), 12, 18);
end;

constructor TXmlPrimitiveValueConverter.Create;
begin
  {$IF COMPILERVERSION > 21}
  FDefaultFormatSettings := TFormatSettings.Create;
  {$IFEND}
  FDefaultFormatSettings.DateSeparator := '-';
  FDefaultFormatSettings.DecimalSeparator := '.';
  FDefaultFormatSettings.ShortTimeFormat := 'hh:nn:ss.zzz';
  FDefaultFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
end;

procedure TXmlPrimitiveValueConverter.StringToValue(const AStringValue: String; var AValue: TValue);
begin
 case AValue.Kind of
    tkInteger, tkInt64:
    begin
      AValue := TValue.FromOrdinal(AValue.TypeInfo, StrToInt64(AStringValue));
    end;
    tkChar,
    tkString,
    tkWChar,
    tkLString,
    tkWString,
    tkUString:
    begin
      AValue := TValue.From<string>(VarToStrDef(AStringValue, ''));
    end;
    tkEnumeration:
    begin
      AValue := TValue.FromOrdinal(AValue.TypeInfo,
        GetEnumValue(AValue.TypeInfo, AStringValue));
    end;
    tkFloat:
    begin
      if AValue.IsDate then
      begin
        AValue := TValue.From<TDate>(ConvertStringToDate(AStringValue));
      end else
      if AValue.IsDateTime then
      begin
        AValue := TValue.From<TDateTime>(ConvertStringToDateTime(AStringValue));
      end else
      if AValue.IsTime then
      begin
        AValue := TValue.From<TTime>(ConvertStringToTime(AStringValue));
      end
      else
      begin
        AValue := ConvertStringToFloat(AStringValue);
      end;
    end;
    tkSet:
    begin
      TValue.Make(StringToSet(AValue.TypeInfo, AStringValue), AValue.TypeInfo, AValue);
    end;
    else
      Guard.RaisePrimitiveValueNotSupportedException(AValue);
  end;
end;

function TXmlPrimitiveValueConverter.ValueToString(const AValue: TValue): string;
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
    tkSet:
      Result := AValue.ToString;
    tkFloat:
      begin
        if AValue.IsDate then
          Result := ConvertDateToString(AValue.AsDate)
        else
        if AValue.IsDateTime then
          Result := ConvertDateTimeToString(AValue.AsDateTime)
        else
        if AValue.IsTime then
          Result := ConvertTimeToString(AValue.AsTime)
        else
          Result := ConvertFloatToString(AValue.AsExtended)
      end;
    else
      Guard.RaisePrimitiveValueNotSupportedException(AValue);
  end;
end;

end.
