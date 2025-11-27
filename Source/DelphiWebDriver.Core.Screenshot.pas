{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.Screenshot;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.NetEncoding,
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebDriverScreenshot = class(TInterfacedObject, IWebDriverScreenshot)
  private
    [weak]
    FDriver: IWebDriver;
  public
    constructor Create(ADriver: IWebDriver);
    function TakeScreenshot: TBytes;
    procedure SaveScreenshotToFile(const FileName: string);
    function TakeElementScreenshot(By: TBy): TBytes;
    procedure SaveElementScreenshotToFile(By: TBy; const FileName: string);
    function PrintPdfPage: string;
    function SavePrintedPdfPage(const FileName: string): Boolean;
  end;

implementation

{ TWebDriverScreenshot }

constructor TWebDriverScreenshot.Create(ADriver: IWebDriver);
begin
  inherited Create;
  FDriver := ADriver;
end;

function TWebDriverScreenshot.PrintPdfPage: string;
var
  Body: TJSONObject;
  Res: TJSONValue;
begin
  Body := TJSONObject.Create;
  try
    Res := FDriver.Commands.SendCommand(
      'POST',
      '/session/' + FDriver.Sessions.GetSessionId + '/print',
      Body
    );
    try
      Result := Res.GetValue<string>('value');
    finally
      Res.Free;
    end;
  finally
    Body.Free;
  end;
end;

function TWebDriverScreenshot.SavePrintedPdfPage(const FileName: string): Boolean;
var
  Base64Pdf: string;
  PdfBytes: TBytes;
  FS: TFileStream;
begin
  Result := False;
  Base64Pdf := PrintPdfPage;
  if Base64Pdf = '' then
    Exit;
  PdfBytes := TNetEncoding.Base64.DecodeStringToBytes(Base64Pdf);
  FS := TFileStream.Create(FileName, fmCreate);
  try
    FS.WriteBuffer(PdfBytes, Length(PdfBytes));
    Result := True;
  finally
    FS.Free;
  end;
end;

procedure TWebDriverScreenshot.SaveElementScreenshotToFile(By: TBy; const FileName: string);
var
  Bytes: TBytes;
  FS: TFileStream;
begin
  Bytes := TakeElementScreenshot(By);
  FS := TFileStream.Create(FileName, fmCreate);
  try
    FS.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    FS.Free;
  end;
end;

procedure TWebDriverScreenshot.SaveScreenshotToFile(const FileName: string);
var
  Bytes: TBytes;
  FS: TFileStream;
begin
  Bytes := TakeScreenshot;
  FS := TFileStream.Create(FileName, fmCreate);
  try
    FS.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    FS.Free;
  end;
end;

function TWebDriverScreenshot.TakeElementScreenshot(By: TBy): TBytes;
var
  Elem: IWebElement;
  JSON: TJSONValue;
  Base64Str: string;
begin
  Elem := nil;
  try
    Elem := FDriver.Elements.FindElement(By);
  except
    on E: EWebDriverError do
      (FDriver.Events as IWebDriverEventsInternal).
        TriggerError(Format('[TWebDriverScreenshot.TakeElementScreenshot] : Element not found for screenshot: %s=%s', [By.Strategy, By.Value]));
  end;
  if not Assigned(Elem) then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  JSON := FDriver.Commands.SendCommand(
    'GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/element/' + Elem.ElementId + '/screenshot'
  );
  try
    Base64Str := JSON.GetValue<string>('value');
    Result := TNetEncoding.Base64.DecodeStringToBytes(Base64Str);
  finally
    JSON.Free;
  end;
end;

function TWebDriverScreenshot.TakeScreenshot: TBytes;
var
  JSON: TJSONValue;
  Base64Str: string;
begin
  JSON := FDriver.Commands.SendCommand('GET', '/session/' + FDriver.Sessions.GetSessionId + '/screenshot');
  try
    Base64Str := JSON.GetValue<string>('value');
    Result := TNetEncoding.Base64.DecodeStringToBytes(Base64Str);
  finally
    JSON.Free;
  end;
end;

end.
