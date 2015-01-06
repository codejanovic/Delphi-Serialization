unit Delphi.Serialization.ExceptionHelper;

interface

uses
  Spring,
  System.Rtti;

type
  GuardSerializationHelper = record helper for Guard
  public
    class procedure RaiseSerializationTypeNotSupportedException(const AValue: TValue); static;
    class procedure RaisePrimitiveValueNotSupportedException(const AValue: TValue); static;
    class procedure RaiseDeserializerException(const AExceptionMessage: String); overload; static;
    class procedure RaiseDeserializerException(const AExceptionMessage: String; const AArguments: Array of const); overload; static;
    class procedure RaiseSerializerException(const AExceptionMessage: String); overload; static;
    class procedure RaiseSerializerException(const AExceptionMessage: String; const AArguments: Array of const); overload; static;
  end;

implementation

uses
  Delphi.Serialization,
  Spring.SystemUtils, System.SysUtils;

{ GuardSerializationHelper }

class procedure GuardSerializationHelper.RaiseSerializationTypeNotSupportedException(const AValue: TValue);
begin
  raise ESerializationTypeNotSupportedError.Create('Value-Kind "' + TEnum.GetName<TTypeKind>(AValue.Kind) + '" not supported');
end;

class procedure GuardSerializationHelper.RaiseDeserializerException(const AExceptionMessage: String);
begin
  raise EDeserializerError.Create(AExceptionMessage);
end;

class procedure GuardSerializationHelper.RaiseSerializerException(const AExceptionMessage: String);
begin
  raise ESerializerError.Create(AExceptionMessage);
end;

class procedure GuardSerializationHelper.RaiseDeserializerException(
  const AExceptionMessage: String;
  const AArguments: array of const);
begin
  RaiseDeserializerException(Format(AExceptionMessage, AArguments));
end;

class procedure GuardSerializationHelper.RaiseSerializerException(
  const AExceptionMessage: String;
  const AArguments: array of const);
begin
  RaiseSerializerException(Format(AExceptionMessage, AArguments));
end;

class procedure GuardSerializationHelper.RaisePrimitiveValueNotSupportedException(
  const AValue: TValue);
begin
  raise EPrimitiveValueNotSupportedError.Create('Value-Kind "' + TEnum.GetName<TTypeKind>(AValue.Kind) + '" not supported');
end;

end.
