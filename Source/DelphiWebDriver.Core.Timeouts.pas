{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.Timeouts;

interface

uses
  System.JSON,
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebDriverTimeouts = class(TInterfacedObject, IWebDriverTimeouts)
  private
    [weak]
    FDriver: IWebDriver;
  public
    constructor Create(ADriver: IWebDriver);
    function GetTimeouts: TWebDriverTimeoutsConfig;
    procedure SetTimeouts(const Timeouts: TWebDriverTimeoutsConfig);
  end;

implementation

{ TWebDriverTimeouts }

constructor TWebDriverTimeouts.Create(ADriver: IWebDriver);
begin
  inherited Create;
  FDriver := ADriver;
end;

function TWebDriverTimeouts.GetTimeouts: TWebDriverTimeoutsConfig;
var
  Value: TJSONObject;
  Resp: TJSONValue;
begin
  Resp := FDriver.Commands.SendCommand('GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/timeouts');
  try
    if not Resp.TryGetValue<TJSONObject>('value', Value) then
      (FDriver.Events as IWebDriverEventsInternal).TriggerError('Invalid GET timeouts response: ' + Resp.ToString);
    Result.Script := Value.GetValue<Integer>('script');
    Result.PageLoad := Value.GetValue<Integer>('pageLoad');
    Result.Implicit := Value.GetValue<Integer>('implicit');
  finally
    Resp.Free;
  end;
end;

procedure TWebDriverTimeouts.SetTimeouts(const Timeouts: TWebDriverTimeoutsConfig);
var
  Body: TJSONObject;
  Resp: TJSONValue;
begin
  Body := TJSONObject.Create;
  try
    Body.AddPair('implicit', TJSONNumber.Create(Timeouts.Implicit));
    Body.AddPair('pageLoad', TJSONNumber.Create(Timeouts.PageLoad));
    Body.AddPair('script', TJSONNumber.Create(Timeouts.Script));
    Resp := FDriver.Commands.SendCommand(
      'POST',
      '/session/' + FDriver.Sessions.GetSessionId + '/timeouts',
      Body
    );
    Resp.Free;
  finally
    Body.Free;
  end;
end;

end.
