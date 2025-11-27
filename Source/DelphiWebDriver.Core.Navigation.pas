{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.Navigation;

interface

uses
  System.JSON,
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebDriverNavigation = class(TInterfacedObject, IWebDriverNavigation)
  private
    [weak]
    FDriver: IWebDriver;
  public
    constructor Create(ADriver: IWebDriver);
    procedure GoToURL(const Url: string);
    function GetTitle: string;
    function GetCurrentUrl: string;
    procedure GoBack;
    procedure GoForward;
    procedure Refresh;
  end;

implementation

{ TWebDriverNavigation }

constructor TWebDriverNavigation.Create(ADriver: IWebDriver);
begin
  inherited Create;
  FDriver := ADriver;
end;

function TWebDriverNavigation.GetCurrentUrl: string;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Commands.SendCommand('GET', '/session/' + FDriver.Sessions.GetSessionId + '/url');
  try
    Result := JSON.GetValue<string>('value');
  finally
    JSON.Free;
  end;
end;

function TWebDriverNavigation.GetTitle: string;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Commands.SendCommand('GET', '/session/' + FDriver.Sessions.GetSessionId + '/title');
  try
    Result := JSON.GetValue<string>('value');
  finally
    JSON.Free;
  end;
end;

procedure TWebDriverNavigation.GoBack;
var
  JSON: TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    (FDriver.Events as IWebDriverEventsInternal).TriggerLoadStart;

    FDriver.Commands.SendCommand('POST', '/session/' + FDriver.Sessions.GetSessionId + '/back',
      JSON).Free;

    FDriver.Wait.UntilPageLoad;
    (FDriver.Events as IWebDriverEventsInternal).TriggerLoadComplete;
  finally
    JSON.Free;
  end;
end;

procedure TWebDriverNavigation.GoForward;
var
  JSON: TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    (FDriver.Events as IWebDriverEventsInternal).TriggerLoadStart;

    FDriver.Commands.SendCommand('POST', '/session/' + FDriver.Sessions.GetSessionId + '/forward',
      JSON).Free;

    FDriver.Wait.UntilPageLoad;
    (FDriver.Events as IWebDriverEventsInternal).TriggerLoadComplete;
  finally
    JSON.Free;
  end;
end;

procedure TWebDriverNavigation.GoToURL(const Url: string);
var
  JSON: TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('url', Url);

    (FDriver.Events as IWebDriverEventsInternal).TriggerLoadStart;

    FDriver.Commands.SendCommand('POST',
      '/session/' + FDriver.Sessions.GetSessionId + '/url',
      JSON
    ).Free;

    FDriver.Wait.UntilPageLoad;
    (FDriver.Events as IWebDriverEventsInternal).TriggerLoadComplete;
  finally
    JSON.Free;
  end;
end;

procedure TWebDriverNavigation.Refresh;
var
  JSON: TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    (FDriver.Events as IWebDriverEventsInternal).TriggerLoadStart;

    FDriver.Commands.SendCommand('POST', '/session/' + FDriver.Sessions.GetSessionId + '/refresh',
      JSON).Free;

    FDriver.Wait.UntilPageLoad;
    (FDriver.Events as IWebDriverEventsInternal).TriggerLoadComplete;
  finally
    JSON.Free;
  end;
end;

end.
