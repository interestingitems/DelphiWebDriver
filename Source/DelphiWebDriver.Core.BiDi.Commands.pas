{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.BiDi.Commands;

interface

uses
  System.SysUtils,
  System.JSON,
  DelphiWebDriver.Websocket,
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebDriverBiDiCommands = class(TInterfacedObject, IWebDriverBiDiCommands)
  private
    [weak]
    FDriver: IWebDriver;
    FWebSocket: TWebDriverWebSocket;
    FCommandIdCounter: Integer;
    function Connect: Boolean;
    procedure Disconnect;
    procedure OnMessage(Sender: TObject; const Msg: string);
    procedure OnConnect(Sender: TObject);
    procedure OnDisconnect(Sender: TObject);
    procedure OnError(Sender: TObject; const Error: string);
    function GenerateCommandId: Integer;
  public
    constructor Create(ADriver: IWebDriver);
    destructor Destroy; override;
    procedure SendCommand(const ACommand: string); overload;
    procedure SendCommand(const ACommand: TJSONObject); overload;
    procedure Subscribe(const EventTypes: array of string); overload;
    procedure Subscribe(const EventTypes: TJSONArray); overload;
    procedure Subscribe(const EventType: string; Params: TJSONObject); overload;
    procedure Unsubscribe(const EventType: string);
    procedure SubscribeToNetworkEvents;
  end;

implementation

{ TWebDriverBiDiCommands }

constructor TWebDriverBiDiCommands.Create(ADriver: IWebDriver);
begin
  inherited Create;
  FDriver := ADriver;
  FCommandIdCounter := 0;
  Connect;
end;

destructor TWebDriverBiDiCommands.Destroy;
begin
  Disconnect;
  inherited;
end;

function TWebDriverBiDiCommands.GenerateCommandId: Integer;
begin
  Inc(FCommandIdCounter);
  Result := FCommandIdCounter;
end;

function TWebDriverBiDiCommands.Connect: Boolean;
begin
  Result := False;
  try
    if FDriver.BrowserConfig.Browser = wdbOpera then
      begin
        (FDriver.Events as IWebDriverEventsInternal).TriggerError('Opera BiDi Is Not Supported Yet');
        Exit;
      end;

    if Assigned(FWebSocket) and FWebSocket.Connected then
      Exit;

    if FDriver.Sessions.GetWebSocketUrl.IsEmpty then
      (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverBiDiCommands.Connect] : No Active WebDriver Session Found For BiDi Connection');

    FWebSocket := TWebDriverWebSocket.Create;
    FWebSocket.OnMessage := OnMessage;
    FWebSocket.OnConnect := OnConnect;
    FWebSocket.OnDisconnect := OnDisconnect;
    FWebSocket.OnError := OnError;
    FWebSocket.Host := FDriver.Sessions.GetWebSocketUrl;
    FWebSocket.Connect;
    Result := FWebSocket.Connected;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

procedure TWebDriverBiDiCommands.Disconnect;
begin
  if Assigned(FWebSocket) then
  begin
    FWebSocket.Disconnect;
    FreeAndNil(FWebSocket);
  end;
end;

procedure TWebDriverBiDiCommands.OnConnect(Sender: TObject);
begin
  //
end;

procedure TWebDriverBiDiCommands.OnDisconnect(Sender: TObject);
begin
  //
end;

procedure TWebDriverBiDiCommands.OnError(Sender: TObject; const Error: string);
begin
  (FDriver.Events as IWebDriverEventsInternal).TriggerError(Error);
end;

procedure TWebDriverBiDiCommands.OnMessage(Sender: TObject; const Msg: string);
begin
  (FDriver.Events as IWebDriverEventsInternal).TriggerBiDiMessage(Msg);
end;

procedure TWebDriverBiDiCommands.Subscribe(const EventType: string; Params: TJSONObject);
var
  Command: TJSONObject;
  SubscriptionParams: TJSONObject;
  CommandId: Integer;
begin
  Command := TJSONObject.Create;
  try
    CommandId := GenerateCommandId;
    Command.AddPair('id', TJSONNumber.Create(CommandId));
    Command.AddPair('method', 'session.subscribe');

    SubscriptionParams := TJSONObject.Create;
    try
      if Assigned(Params) then
      begin
        SubscriptionParams := Params.Clone as TJSONObject;
      end
      else
      begin
        SubscriptionParams.AddPair('events', TJSONArray.Create.Add(EventType));
      end;

      Command.AddPair('params', SubscriptionParams);

      SendCommand(Command);
    finally
      SubscriptionParams.Free;
    end;
  finally
    Command.Free;
  end;
end;

procedure TWebDriverBiDiCommands.Subscribe(const EventTypes: array of string);
var
  EventsArray: TJSONArray;
  I: Integer;
begin
  EventsArray := TJSONArray.Create;
  try
    for I := 0 to High(EventTypes) do
      EventsArray.Add(EventTypes[I]);

    Subscribe(EventsArray);
  finally
    EventsArray.Free;
  end;
end;

procedure TWebDriverBiDiCommands.Subscribe(const EventTypes: TJSONArray);
var
  Command: TJSONObject;
  Params: TJSONObject;
  CommandId: Integer;
begin
  Command := TJSONObject.Create;
  try
    CommandId := GenerateCommandId;
    Command.AddPair('id', TJSONNumber.Create(CommandId));
    Command.AddPair('method', 'session.subscribe');

    Params := TJSONObject.Create;
    Params.AddPair('events', EventTypes.Clone as TJSONArray);
    Command.AddPair('params', Params);

    SendCommand(Command);
  finally
    Command.Free;
  end;
end;

procedure TWebDriverBiDiCommands.Unsubscribe(const EventType: string);
var
  Command: TJSONObject;
  Params: TJSONObject;
  CommandId: Integer;
begin
  Command := TJSONObject.Create;
  Params := TJSONObject.Create;
  try
    CommandId := GenerateCommandId;
    Command.AddPair('id', TJSONNumber.Create(CommandId));
    Command.AddPair('method', 'session.unsubscribe');
    Params.AddPair('events', TJSONArray.Create.Add(EventType));
    Command.AddPair('params', Params);

    SendCommand(Command);
  finally
    Command.Free;
  end;
end;

procedure TWebDriverBiDiCommands.SubscribeToNetworkEvents;
begin
  Subscribe([
    'network.beforeRequestSent',
    'network.fetchError',
    'network.responseCompleted'
  ]);
end;

procedure TWebDriverBiDiCommands.SendCommand(const ACommand: TJSONObject);
begin
  if FDriver.BrowserConfig.Browser = wdbOpera then
    begin
      (FDriver.Events as IWebDriverEventsInternal).TriggerError('Opera BiDi Is Not Supported Yet');
      Exit;
    end;

  if (not Assigned(FWebSocket)) or (not FWebSocket.Connected) then
    Connect;

  if not FWebSocket.Connected then
    begin
      (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverBiDiCommands.SendCommand] : BiDi WebSocket Is Not Connected');
      Exit;
    end;

  FWebSocket.WriteData(ACommand.ToJSON);
end;

procedure TWebDriverBiDiCommands.SendCommand(const ACommand: string);
begin
  if FDriver.BrowserConfig.Browser = wdbOpera then
    begin
      (FDriver.Events as IWebDriverEventsInternal).TriggerError('Opera BiDi Is Not Supported Yet');
      Exit;
    end;

  if (not Assigned(FWebSocket)) or (not FWebSocket.Connected) then
    Connect;

  if not FWebSocket.Connected then
    begin
      (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverBiDiCommands.SendCommand] : BiDi WebSocket Is Not Connected');
      Exit;
    end;

  FWebSocket.WriteData(ACommand);
end;

end.
