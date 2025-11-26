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
    FHTTP: THTTPClient;
    FBaseUrl: string;
  public
    constructor Create(BaseURL : String);
    destructor Destroy; override;
    function SendCommand(const Method, Endpoint: string; Body: TJSONObject): TJSONValue;
  end;

implementation

{ TWebDriverCommands }

constructor TWebDriverCommands.Create(BaseURL: String);
begin
  inherited Create;
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
  LUrl := FBaseUrl + Endpoint;

  SetLength(Headers, 1);
  Headers[0].Name := 'Content-Type';
  Headers[0].Value := 'application/json; charset=utf-8';

  Stream := nil;
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
      raise EWebDriverError.Create
        ('Invalid JSON response received from WebDriver');
  finally
    Stream.Free;
  end;
end;

end.
