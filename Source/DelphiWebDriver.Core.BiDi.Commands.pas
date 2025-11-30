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
    function Connect: Boolean;
    procedure Disconnect;
    procedure OnMessage(Sender: TObject; const Msg: string);
    procedure OnConnect(Sender: TObject);
    procedure OnDisconnect(Sender: TObject);
    procedure OnError(Sender: TObject; const Msg: string);
  public
    constructor Create(ADriver: IWebDriver);
    destructor Destroy; override;
    procedure SendCommand(const ACommand: string);
  end;

implementation

{ TWebDriverBiDiCommands }

constructor TWebDriverBiDiCommands.Create(ADriver: IWebDriver);
begin
  inherited Create;
  FDriver := ADriver;
  Connect;
end;

destructor TWebDriverBiDiCommands.Destroy;
begin
  Disconnect;
  inherited;
end;

function TWebDriverBiDiCommands.Connect: Boolean;
begin
  Result := False;
  try
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

procedure TWebDriverBiDiCommands.OnError(Sender: TObject; const Msg: string);
begin
  //
end;

procedure TWebDriverBiDiCommands.OnMessage(Sender: TObject; const Msg: string);
begin
  //
end;

procedure TWebDriverBiDiCommands.SendCommand(const ACommand: string);
begin
  if (not Assigned(FWebSocket)) or (not FWebSocket.Connected) then
    Connect;

  if not FWebSocket.Connected then
    (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverBiDiCommands.SendCommand] : BiDi WebSocket Is Not Connected');

  FWebSocket.WriteData(ACommand);
end;

end.
