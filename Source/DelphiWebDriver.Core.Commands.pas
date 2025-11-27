{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.Commands;

interface

uses
  System.SysUtils,
  System.JSON,
  System.Classes,
  System.Generics.Collections,
  System.Net.HttpClient,
  System.Net.URLClient,
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebDriverCommands = class(TInterfacedObject, IWebDriverCommands)
  private
    [weak]
    FDriver: IWebDriver;
    FHTTP: THTTPClient;
    FBaseUrl: string;
  public
    constructor Create(ADriver: IWebDriver; BaseURL : String);
    destructor Destroy; override;
    function SendCommand(const Method, Endpoint: string; Body: TJSONObject): TJSONValue;
  end;

implementation

{ TWebDriverCommands }

constructor TWebDriverCommands.Create(ADriver: IWebDriver; BaseURL: String);
begin
  inherited Create;
  FDriver := ADriver;
  FHTTP := THTTPClient.Create;
  FBaseUrl := BaseURL;
end;

destructor TWebDriverCommands.Destroy;
begin
  FHTTP.Free;
  inherited;
end;

function TWebDriverCommands.SendCommand(const Method, Endpoint: string; Body: TJSONObject): TJSONValue;
var
  LUrl: string;
  LResponse: IHTTPResponse;
  Stream: TStringStream;
  Headers: TNetHeaders;
begin
  Result := nil; // make sure to initialize
  LUrl := FBaseUrl + Endpoint;

  SetLength(Headers, 1);
  Headers[0].Name := 'Content-Type';
  Headers[0].Value := 'application/json; charset=utf-8';

  Stream := nil;
  try
    try
      if Assigned(Body) then
        Stream := TStringStream.Create(Body.ToJSON, TEncoding.UTF8)
      else
        Stream := TStringStream.Create('{}', TEncoding.UTF8);

      if Method = 'POST' then
        LResponse := FHTTP.Post(LUrl, Stream, nil, Headers)
      else if Method = 'DELETE' then
        LResponse := FHTTP.Delete(LUrl, nil, Headers)
      else
        LResponse := FHTTP.Get(LUrl, nil, Headers);

      Result := TJSONObject.ParseJSONValue(LResponse.ContentAsString);

      if not Assigned(Result) then
        (FDriver.Events as IWebDriverEventsInternal)
          .TriggerError('[TWebDriverCommands.SendCommand] : Invalid JSON response received from WebDriver = ' + LResponse.ContentAsString);

    except
      on E: Exception do
      begin
        (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverCommands.SendCommand] : ' + E.Message);
      end;
    end;
  finally
    Stream.Free;
  end;
end;

end.
