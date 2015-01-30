[![Stories in Ready](https://badge.waffle.io/traffino/delphi-serialization.png?label=ready&title=Ready)](https://waffle.io/traffino/delphi-serialization)
#Delphi-Serialization

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/traffino/Delphi-Serialization?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
Delphi-Serialization provides functionality for serializing and deserializing Objects to (currently only) XML.
### Roadmap (rough)
- more testing
- more flexibility
- serialize/deserialize to JSON
- and more

### Project-Dependencies
- DunitX (Testframework)
- DSharp 
- Spring4D

### Example
```delphi
var
  LCustomer: ICustomer;
  LSerializationFacade: TSerializationFacade;
  LOutputCustomer: TStringStream;
begin
  LCustomer := TCustomer.Create;
  LSerializationFacade := TSerializationFacade.Create;
  LOutputCustomer := TStringStream.Create;
  try
    LSerializationFacade.Serialize<ICustomer>(LCustomer, LOutputCustomer);

    //Do something with the serialized xml-string LOutput.DataString
  finally
    FreeAndNil(LOutputCustomer);
    FreeAndNil(LSerializationFacade);
  end;
end;
```
