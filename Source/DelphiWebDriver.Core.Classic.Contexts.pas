{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.Classic.Contexts;

interface

uses
  System.SysUtils,
  System.JSON,
  System.Types,
  System.Generics.Collections,
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebDriverContexts = class(TInterfacedObject, IWebDriverContexts)
  private
    [weak]
    FDriver: IWebDriver;
  public
    constructor Create(ADriver: IWebDriver);
    procedure SwitchToFrameElement(const Element: IWebElement);
    procedure SwitchToFrame(const FrameName: string);
    procedure SwitchToDefaultContent;
    function GetWindowHandle: string;
    function GetWindowHandles: TArray<string>;
    procedure SwitchToWindow(const Handle: string);
    procedure SwitchToMainWindow;
    procedure SwitchToWindowIndex(Index: Integer);
    function GetCurrentWindowIndex: Integer;
    procedure CloseWindow;
    function NewWindow(const WindowType: string = 'tab'): string;
    procedure MaximizeWindow;
    procedure MinimizeWindow;
    procedure FullscreenWindow;
    procedure SetWindowSize(const Width, Height: Integer);
    function GetWindowSize: TSize;
    procedure SetWindowPosition(const X, Y: Integer);
    function GetWindowPosition: TPoint;
  end;

implementation

{ TWebDriverContexts }

procedure TWebDriverContexts.CloseWindow;
begin
  FDriver.Classic.Commands.SendCommand('DELETE', '/session/' + FDriver.Sessions.GetSessionId + '/window').Free;
end;

constructor TWebDriverContexts.Create(ADriver: IWebDriver);
begin
  inherited Create;
  FDriver := ADriver;
end;

procedure TWebDriverContexts.SetWindowPosition(const X, Y: Integer);
var
  Body: TJSONObject;
begin
  Body := TJSONObject.Create;
  try
    Body.AddPair('x', X);
    Body.AddPair('y', Y);
    FDriver.Classic.Commands.SendCommand('POST', '/session/'+ FDriver.Sessions.GetSessionId +'/window/rect', Body).Free;
  finally
    Body.Free;
  end;
end;

procedure TWebDriverContexts.SetWindowSize(const Width, Height: Integer);
var
  Body: TJSONObject;
  R: TJSONValue;
begin
  Body := TJSONObject.Create;
  R := nil;
  try
    Body.AddPair('width', TJSONNumber.Create(Width));
    Body.AddPair('height', TJSONNumber.Create(Height));
    R := FDriver.Classic.Commands.SendCommand(
      'POST',
      '/session/' + FDriver.Sessions.GetSessionId + '/window/rect',
      Body
    );
  finally
    Body.Free;
    R.Free;
  end;
end;

procedure TWebDriverContexts.FullscreenWindow;
var
  Body: TJSONObject;
  R: TJSONValue;
begin
  Body := TJSONObject.Create;
  R := nil;
  try
    R := FDriver.Classic.Commands.SendCommand('POST', '/session/' + FDriver.Sessions.GetSessionId + '/window/fullscreen', Body);
  finally
    Body.Free;
    R.Free;
  end;
end;

function TWebDriverContexts.GetCurrentWindowIndex: Integer;
var
  Handles: TArray<string>;
  Current: string;
  I: Integer;
begin
  Handles := GetWindowHandles;
  Current := GetWindowHandle;
  for I := 0 to High(Handles) do
    if Handles[I] = Current then
      Exit(I);
  Result := -1;
end;

function TWebDriverContexts.GetWindowPosition: TPoint;
var
  Resp: TJSONValue;
  ValueObj: TJSONObject;
begin
  Resp := FDriver.Classic.Commands.SendCommand('GET', '/session/'+ FDriver.Sessions.GetSessionId +'/window/rect', nil);
  try
    ValueObj := Resp.GetValue<TJSONObject>('value');
      if not Assigned(ValueObj) then
        (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverContexts.GetWindowPosition] : no value returned');
    Result.X := ValueObj.GetValue<Integer>('x');
    Result.Y := ValueObj.GetValue<Integer>('y');
  finally
    Resp.Free;
  end;
end;

function TWebDriverContexts.GetWindowSize: TSize;
var
  Resp: TJSONValue;
  ValueObj: TJSONObject;
begin
  Resp := FDriver.Classic.Commands.SendCommand('GET', '/session/'+ FDriver.Sessions.GetSessionId +'/window/rect', nil);
  try
    ValueObj := Resp.GetValue<TJSONObject>('value');
      if not Assigned(ValueObj) then
        (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverContexts.GetWindowSize] : no value returned');
    Result.cx := ValueObj.GetValue<Integer>('width');
    Result.cy := ValueObj.GetValue<Integer>('height');
  finally
    Resp.Free;
  end;
end;

function TWebDriverContexts.GetWindowHandle: string;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET', '/session/' + FDriver.Sessions.GetSessionId + '/window');
  try
    Result := JSON.GetValue<string>('value');
  finally
    JSON.Free;
  end;
end;

function TWebDriverContexts.GetWindowHandles: TArray<string>;
var
  JSON: TJSONValue;
  Arr: TJSONArray;
  I: Integer;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET', '/session/' + FDriver.Sessions.GetSessionId + '/window/handles');
  try
    Arr := JSON.GetValue<TJSONArray>('value');

    SetLength(Result, Arr.Count);
    for I := 0 to Arr.Count - 1 do
      Result[I] := Arr.Items[I].Value;
  finally
    JSON.Free;
  end;
end;

procedure TWebDriverContexts.MaximizeWindow;
var
  Body: TJSONObject;
  R: TJSONValue;
begin
  Body := TJSONObject.Create;
  R := nil;
  try
    R := FDriver.Classic.Commands.SendCommand('POST', '/session/' + FDriver.Sessions.GetSessionId + '/window/maximize', Body);
  finally
    Body.Free;
    R.Free;
  end;
end;

procedure TWebDriverContexts.MinimizeWindow;
var
  Body: TJSONObject;
  R: TJSONValue;
begin
  Body := TJSONObject.Create;
  R := nil;
  try
    R := FDriver.Classic.Commands.SendCommand('POST', '/session/' + FDriver.Sessions.GetSessionId + '/window/minimize', Body);
  finally
    Body.Free;
    R.Free;
  end;
end;

function TWebDriverContexts.NewWindow(const WindowType: string): string;
var
  JSON: TJSONValue;
  Body: TJSONObject;
  ValueObj: TJSONObject;
begin
  Body := TJSONObject.Create;
  try
    Body.AddPair('type', WindowType);

    JSON := FDriver.Classic.Commands.SendCommand('POST', '/session/' + FDriver.Sessions.GetSessionId + '/window/new', Body);
    try
      ValueObj := JSON.GetValue<TJSONObject>('value');
      if not Assigned(ValueObj) then
        (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverContexts.NewWindow] : no value returned');
      Result := ValueObj.GetValue<string>('handle');
    finally
      JSON.Free;
    end;
  finally
    Body.Free;
  end;
end;

procedure TWebDriverContexts.SwitchToDefaultContent;
var
  JSON: TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('id', TJSONNull.Create);
    FDriver.Classic.Commands.SendCommand('POST', '/session/' + FDriver.Sessions.GetSessionId + '/frame', JSON).Free;
  finally
    JSON.Free;
  end;
end;

procedure TWebDriverContexts.SwitchToFrame(const FrameName: string);
var
  JSON: TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('id', TJSONString.Create(FrameName));
    FDriver.Classic.Commands.SendCommand('POST', '/session/' + FDriver.Sessions.GetSessionId + '/frame', JSON).Free;
  finally
    JSON.Free;
  end;
end;

procedure TWebDriverContexts.SwitchToFrameElement(const Element: IWebElement);
var
  JSON: TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('id', TJSONObject.Create.AddPair('ELEMENT', Element.ElementId)
      .AddPair('element-6066-11e4-a52e-4f735466cecf', Element.ElementId));
    FDriver.Classic.Commands.SendCommand('POST', '/session/' + FDriver.Sessions.GetSessionId + '/frame', JSON).Free;;
  finally
    JSON.Free;
  end;
end;

procedure TWebDriverContexts.SwitchToMainWindow;
begin
  if FDriver.Sessions.GetWindowHandle = '' then
    (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverContexts.SwitchToMainWindow] : Main window handle not stored.');
  SwitchToWindow(FDriver.Sessions.GetWindowHandle);
end;

procedure TWebDriverContexts.SwitchToWindow(const Handle: string);
var
  JSON: TJSONObject;
  SessionId: string;
  Endpoint: string;
begin
  SessionId := FDriver.Sessions.GetSessionId;
  if FDriver.BrowserConfig.Browser = wdbOpera then
  begin
    Endpoint := '/session/' + SessionId + '/window';
    JSON := TJSONObject.Create;
    try
      JSON.AddPair('name', Handle);
      FDriver.Classic.Commands.SendCommand('POST', Endpoint, JSON).Free;
    finally
      JSON.Free;
    end;
    Exit;
  end;
  Endpoint := '/session/' + SessionId + '/window';
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('handle', Handle);
    FDriver.Classic.Commands.SendCommand('POST', Endpoint, JSON).Free;
  finally
    JSON.Free;
  end;
end;

procedure TWebDriverContexts.SwitchToWindowIndex(Index: Integer);
var
  Handles: TArray<string>;
  Body: TJSONObject;
  JSON: TJSONValue;
begin
  Handles := GetWindowHandles;
  if (Index < 0) or (Index >= Length(Handles)) then
    (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverContexts.SwitchToWindowIndex] : Invalid window index ' + Index.ToString);
  Body := TJSONObject.Create;
  try
    Body.AddPair('handle', Handles[Index]);
    JSON := FDriver.Classic.Commands.SendCommand(
      'POST',
      '/session/' + FDriver.Sessions.GetSessionId + '/window',
      Body
    );
    JSON.Free;
  finally
    Body.Free;
  end;
end;

end.
