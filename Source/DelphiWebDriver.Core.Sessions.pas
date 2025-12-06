{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.Sessions;

interface

uses
  System.SysUtils,
  System.JSON,
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebDriverSessions = class(TInterfacedObject, IWebDriverSessions)
  private
    [weak]
    FDriver: IWebDriver;
    FSessionId: string;
    FWindowHandle: string;
    FWebSocketUrl: string;
  public
    constructor Create(ADriver: IWebDriver);
    function StartSession: Boolean;
    procedure Quit;
    function GetSessionId: string;
    function GetWindowHandle: string;
    function GetWebSocketUrl: string;
  end;

implementation

{ TWebDriverSessions }

constructor TWebDriverSessions.Create(ADriver: IWebDriver);
begin
  inherited Create;
  FDriver := ADriver;
end;

function TWebDriverSessions.GetWebSocketUrl: string;
begin
  Result := FWebSocketUrl;
end;

function TWebDriverSessions.GetWindowHandle: string;
begin
  Result := FWindowHandle;
end;

function TWebDriverSessions.GetSessionId: string;
begin
  Result := FSessionId;
end;

procedure TWebDriverSessions.Quit;
begin
  if FSessionId <> '' then
    FDriver.Classic.Commands.SendCommand('DELETE', '/session/' + FSessionId).Free;
end;

function TWebDriverSessions.StartSession: Boolean;
label
  ParseResponse;
var
  CapObj, TopObj, AlwaysMatch: TJSONObject;
  LRes, LValue: TJSONValue;
  LSessionObj: TJSONObject;
  StatusCode: Integer;
  ErrorValueObj: TJSONObject;
  ErrorMessage: string;
begin
  FSessionId := '';
  FWindowHandle := '';
  FWebSocketUrl := '';
  LSessionObj := nil;

  CapObj := FDriver.Capabilities.ToJSON;
  try
    try
      if FDriver.BrowserConfig.Browser = wdbOpera then
      begin
        TopObj := TJSONObject.Create;
        try
          TopObj.AddPair('desiredCapabilities', CapObj.Clone as TJSONObject);
          LRes := FDriver.Classic.Commands.SendCommand('POST', '/session', TopObj);
        finally
          TopObj.Free;
        end;
        goto ParseResponse;
      end;

      TopObj := TJSONObject.Create;
      try
        AlwaysMatch := TJSONObject.Create;
        AlwaysMatch.AddPair('alwaysMatch', CapObj.Clone as TJSONObject);
        TopObj.AddPair('capabilities', AlwaysMatch);
        LRes := FDriver.Classic.Commands.SendCommand('POST', '/session', TopObj);
      finally
        TopObj.Free;
      end;

      ParseResponse:
      try
        if not Assigned(LRes) then
        begin
          (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverSessions.StartSession] : No response from WebDriver server');
          Exit(False);
        end;

        if LRes.TryGetValue<Integer>('status', StatusCode) and (StatusCode <> 0) then
        begin
          ErrorMessage := 'WebDriver session creation failed';

          if LRes.TryGetValue<TJSONObject>('value', ErrorValueObj) then
          begin
            if ErrorValueObj.TryGetValue<string>('message', ErrorMessage) then
            begin
              ErrorMessage := StringReplace(ErrorMessage, #10, ' ', [rfReplaceAll]);
              ErrorMessage := StringReplace(ErrorMessage, #13, ' ', [rfReplaceAll]);
              ErrorMessage := Trim(ErrorMessage);
            end
            else if ErrorValueObj.TryGetValue<string>('error', ErrorMessage) then
            begin
              ErrorMessage := 'WebDriver error: ' + ErrorMessage;
            end;
          end;

          (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverSessions.StartSession] : ' + ErrorMessage);
          Exit(False);
        end;

        LValue := LRes.GetValue<TJSONValue>('value');
        if Assigned(LValue) and (LValue is TJSONObject) then
        begin
          LSessionObj := TJSONObject(LValue);
          LSessionObj.TryGetValue<string>('sessionId', FSessionId);
        end;

        if FSessionId = '' then
          LRes.TryGetValue<string>('sessionId', FSessionId);

        if FSessionId = '' then
        begin
          (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverSessions.StartSession] : SessionId not found: ' + LRes.ToString);
          Exit(False);
        end;

        try
          FWindowHandle := FDriver.Classic.Contexts.GetWindowHandle;
        except
          on E: Exception do
          begin
            FWindowHandle := '';
            (FDriver.Events as IWebDriverEventsInternal)
              .TriggerError('[TWebDriverSessions.StartSession] : Could not get window handle: ' + E.Message);
          end;
        end;

        FWebSocketUrl := '';

        if FDriver.BrowserConfig.Browser = wdbOpera then
        begin
          if Assigned(LValue) and (LValue is TJSONObject) then
            LSessionObj.TryGetValue<string>('webSocketUrl', FWebSocketUrl);
        end
        else
        begin
          if Assigned(LValue) and (LValue is TJSONObject) then
          begin
            var CapabilitiesObj: TJSONObject := nil;
            if LSessionObj.TryGetValue<TJSONObject>('capabilities', CapabilitiesObj) then
              if Assigned(CapabilitiesObj) then
                CapabilitiesObj.TryGetValue<string>('webSocketUrl', FWebSocketUrl);
          end;
        end;

        if FWebSocketUrl = '' then
        begin
          (FDriver.Events as IWebDriverEventsInternal)
            .TriggerError('[TWebDriverSessions.StartSession] : BiDi WebSocketUrl not returned. BiDi features will not work.');
        end;

        Result := True;
      finally
        if Assigned(LRes) then
          LRes.Free;
      end;
    except
      on E: EJSONException do
      begin
        (FDriver.Events as IWebDriverEventsInternal)
          .TriggerError('[TWebDriverSessions.StartSession] : JSON parsing error: ' + E.Message);
        Result := False;
      end;
      on E: Exception do
      begin
        (FDriver.Events as IWebDriverEventsInternal)
          .TriggerError('[TWebDriverSessions.StartSession] : ' + E.Message);
        Result := False;
      end;
    end;
  finally
    CapObj.Free;
  end;
end;

end.

