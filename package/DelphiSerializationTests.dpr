 program DelphiSerializationTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}
uses
  SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Delphi.Serialization.XmlReader in '..\Delphi.Serialization.XmlReader.pas',
  Delphi.Serialization in '..\Delphi.Serialization.pas',
  Delphi.Serialization.Serializer in '..\Delphi.Serialization.Serializer.pas',
  Delphi.Serialization.XmlWriter in '..\Delphi.Serialization.XmlWriter.pas',
  Delphi.Serialization.Deserializer in '..\Delphi.Serialization.Deserializer.pas',
  Delphi.Serialization.Tests.Main in '..\tests\Delphi.Serialization.Tests.Main.pas',
  Delphi.Serialization.Tests.Testdata.SimpleInterfacedObject in '..\testdata\Delphi.Serialization.Tests.Testdata.SimpleInterfacedObject.pas',
  Delphi.Serialization.Tests.Testdata.SimpleObject in '..\testdata\Delphi.Serialization.Tests.Testdata.SimpleObject.pas',
  Delphi.Serialization.XmlValueConverter in '..\Delphi.Serialization.XmlValueConverter.pas',
  Delphi.Serialization.Tests.Testdata in '..\testdata\Delphi.Serialization.Tests.Testdata.pas',
  Delphi.Serialization.ExceptionHelper in '..\Delphi.Serialization.ExceptionHelper.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //tell the runner how we will log things
    //Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
