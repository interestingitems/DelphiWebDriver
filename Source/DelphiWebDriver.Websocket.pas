{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ** This Unit Is Made With the Help Of LLM **
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Websocket;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  IdTCPClient,
  IdGlobal,
  IdException,
  IdStack,
  DelphiWebDriver.Types;

type
  TWebDriverWebSocket = class
  private
    FConnection: TIdTCPClient;
    FLock: TCriticalSection;
    FOnMessage: TWebDriverWebSocketMessageEvent;
    FOnConnect: TWebDriverWebSocketBasicEvent;
    FOnDisconnect: TWebDriverWebSocketBasicEvent;
    FOnError: TWebDriverWebSocketMessageEvent;
    FHost: string;
    FActive: Boolean;
    FReady: Boolean;
    FKey: string;
    FWorker: TThread;
    FStopping: Boolean;
    FLastPingTime: UInt64;
    FPingInterval: Integer;
    FReconnectAttempts: Integer;
    FMaxReconnectAttempts: Integer;
    FAutoReconnect: Boolean;
    FIsReconnecting: Boolean;
    FConnectionTimeout: Integer;
    FReadTimeout: Integer;
    FIgnoreSocketErrors: Boolean;
    procedure InitConnection;
    procedure MakeKey;
    function GetAccept(const Key: string): string;
    procedure DoHandshake;
    function CheckHandshake: Boolean;
    function MakeFrame(const Data: string; Opcode: Byte): TIdBytes;
    function ReadFrame(var Opcode: Byte; var Data: string): Boolean;
    procedure WorkerLoop;
    procedure StopWorker;
    procedure CloseConnection;
    procedure PostMessage(const Text: string);
    procedure PostConnect;
    procedure PostDisconnect;
    procedure PostError(const Text: string; IsSocketError: Boolean = False);
    function GetTicks: UInt64;
    procedure Delay(MS: Cardinal);
    function CheckConnection: Boolean;
    procedure SendPing;
    procedure AttemptReconnect;
    procedure InternalDisconnect(FromWorker: Boolean = False);
    function IsSocketError(const ErrorMsg: string): Boolean;
    function IsGracefulDisconnect(const ErrorMsg: string): Boolean;
    procedure SafeWriteData(const Data: TIdBytes);
    function SafeReadFrame(var Opcode: Byte; var Data: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Connect;
    procedure Disconnect;
    procedure WriteData(const Text: string);
    property Connected: Boolean read FActive;
    property Host: string read FHost write FHost;
    property OnMessage: TWebDriverWebSocketMessageEvent read FOnMessage write FOnMessage;
    property OnConnect: TWebDriverWebSocketBasicEvent read FOnConnect write FOnConnect;
    property OnDisconnect: TWebDriverWebSocketBasicEvent read FOnDisconnect write FOnDisconnect;
    property OnError: TWebDriverWebSocketMessageEvent read FOnError write FOnError;
    property AutoReconnect: Boolean read FAutoReconnect write FAutoReconnect;
    property MaxReconnectAttempts: Integer read FMaxReconnectAttempts write FMaxReconnectAttempts;
    property PingInterval: Integer read FPingInterval write FPingInterval;
    property ConnectionTimeout: Integer read FConnectionTimeout write FConnectionTimeout;
    property ReadTimeout: Integer read FReadTimeout write FReadTimeout;
    property IgnoreSocketErrors: Boolean read FIgnoreSocketErrors write FIgnoreSocketErrors;
  end;

implementation

uses
  IdURI, IdHashSHA, IdCoderMIME
  {$IFDEF MSWINDOWS}
  , Windows
  {$ENDIF}
  ;

type
  TWebSocketWorker = class(TThread)
  private
    FSocket: TWebDriverWebSocket;
  protected
    procedure Execute; override;
  public
    constructor Create(Socket: TWebDriverWebSocket);
  end;

{ TWebSocketWorker }

constructor TWebSocketWorker.Create(Socket: TWebDriverWebSocket);
begin
  inherited Create(False);
  FSocket := Socket;
  FreeOnTerminate := False;
end;

procedure TWebSocketWorker.Execute;
begin
  if Assigned(FSocket) then
    FSocket.WorkerLoop;
end;

{ TWebDriverWebSocket }

constructor TWebDriverWebSocket.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
  FActive := False;
  FReady := False;
  FStopping := False;
  FWorker := nil;
  FIsReconnecting := False;
  FAutoReconnect := True;
  FReconnectAttempts := 0;
  FMaxReconnectAttempts := 5;
  FPingInterval := 30000;
  FConnectionTimeout := 10000;
  FReadTimeout := 5000;
  FIgnoreSocketErrors := True;
  FLastPingTime := 0;
  InitConnection;
end;

destructor TWebDriverWebSocket.Destroy;
begin
  FStopping := True;
  FIgnoreSocketErrors := True;
  Delay(100);
  InternalDisconnect;
  StopWorker;
  FLock.Free;
  FConnection.Free;
  inherited;
end;

function TWebDriverWebSocket.GetTicks: UInt64;
begin
  {$IFDEF MSWINDOWS}
  Result := GetTickCount64;
  {$ELSE}
  Result := TThread.GetTickCount;
  {$ENDIF}
end;

procedure TWebDriverWebSocket.Delay(MS: Cardinal);
begin
  TThread.Sleep(MS);
end;

procedure TWebDriverWebSocket.InitConnection;
begin
  FConnection := TIdTCPClient.Create(nil);
  FConnection.ReadTimeout := FReadTimeout;
  FConnection.ConnectTimeout := FConnectionTimeout;
  FConnection.Intercept := nil;
  try
    {$IFDEF HAS_IDTCPCLIENT_REUSESOCKET}
    FConnection.ReuseSocket := rsTrue;
    {$ENDIF}

    {$IFDEF HAS_IDTCPCLIENT_USENAGLE}
    FConnection.UseNagle := False;
    {$ENDIF}
  except
  end;
end;

procedure TWebDriverWebSocket.MakeKey;
var
  Bytes: TIdBytes;
  i: Integer;
begin
  SetLength(Bytes, 16);
  for i := 0 to 15 do
    Bytes[i] := Random(256);
  FKey := TIdEncoderMIME.EncodeBytes(Bytes);
end;

function TWebDriverWebSocket.GetAccept(const Key: string): string;
var
  SHA1: TIdHashSHA1;
  Hash: TIdBytes;
begin
  SHA1 := TIdHashSHA1.Create;
  try
    Hash := SHA1.HashString(Key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11');
    Result := TIdEncoderMIME.EncodeBytes(Hash);
  finally
    SHA1.Free;
  end;
end;

procedure TWebDriverWebSocket.DoHandshake;
var
  URI: TIdURI;
  Host: string;
  Path: string;
begin
  URI := TIdURI.Create(FHost);
  try
    Host := URI.Host;
    if not URI.Port.IsEmpty then
      Host := Host + ':' + URI.Port;

    Path := URI.Path + URI.Document;
    if Path = '' then
      Path := '/';

    MakeKey;

    FConnection.IOHandler.WriteLn('GET ' + Path + ' HTTP/1.1');
    FConnection.IOHandler.WriteLn('Host: ' + Host);
    FConnection.IOHandler.WriteLn('Upgrade: websocket');
    FConnection.IOHandler.WriteLn('Connection: Upgrade');
    FConnection.IOHandler.WriteLn('Sec-WebSocket-Key: ' + FKey);
    FConnection.IOHandler.WriteLn('Sec-WebSocket-Version: 13');
    FConnection.IOHandler.WriteLn('');
  finally
    URI.Free;
  end;
end;

function TWebDriverWebSocket.CheckHandshake: Boolean;
var
  Line: string;
  Headers: TStringList;
  Accept, Expected: string;
  ColonPos: Integer;
begin
  Result := False;
  Headers := TStringList.Create;
  try
    try
      Line := FConnection.IOHandler.ReadLn;
      if not Line.Contains('101') then
      begin
        PostError('[TWebDriverWebSocket.CheckHandshake] : ' + Line);
        Exit;
      end;

      repeat
        Line := FConnection.IOHandler.ReadLn;
        if Line <> '' then
        begin
          ColonPos := Pos(':', Line);
          if ColonPos > 0 then
            Headers.Values[Trim(Copy(Line, 1, ColonPos - 1))] := Trim(Copy(Line, ColonPos + 1, MaxInt));
        end;
      until Line = '';

      if (Headers.Values['Upgrade'].ToLower = 'websocket') and
         (Headers.Values['Connection'].ToLower.Contains('upgrade')) then
      begin
        Accept := Headers.Values['Sec-WebSocket-Accept'];
        if Accept <> '' then
        begin
          Expected := GetAccept(FKey);
          Result := Accept = Expected;
        end
        else
        begin
          Result := True;
        end;
      end;
    except
      on E: Exception do
      begin
        PostError('[TWebDriverWebSocket.CheckHandshake] : ' + E.Message, IsSocketError(E.Message));
        Result := False;
      end;
    end;
  finally
    Headers.Free;
  end;
end;

function TWebDriverWebSocket.MakeFrame(const Data: string; Opcode: Byte): TIdBytes;
var
  DataBytes: TIdBytes;
  Frame: TIdBytes;
  Size: Integer;
  Pos: Integer;
  Mask: array[0..3] of Byte;
  i: Integer;
begin
  DataBytes := ToBytes(Data);
  Size := Length(DataBytes);

  if Size <= 125 then
    SetLength(Frame, 2 + 4 + Size)
  else if Size <= 65535 then
    SetLength(Frame, 4 + 4 + Size)
  else
    SetLength(Frame, 10 + 4 + Size);

  Pos := 0;

  Frame[Pos] := $80 or Opcode;
  Inc(Pos);

  if Size <= 125 then
  begin
    Frame[Pos] := $80 or Size;
    Inc(Pos);
  end
  else if Size <= 65535 then
  begin
    Frame[Pos] := $80 or 126;
    Inc(Pos);
    Frame[Pos] := (Size shr 8) and $FF;
    Inc(Pos);
    Frame[Pos] := Size and $FF;
    Inc(Pos);
  end
  else
  begin
    Frame[Pos] := $80 or 127;
    Inc(Pos);
    for i := 1 to 4 do
    begin
      Frame[Pos] := 0;
      Inc(Pos);
    end;
    Frame[Pos] := (Size shr 24) and $FF; Inc(Pos);
    Frame[Pos] := (Size shr 16) and $FF; Inc(Pos);
    Frame[Pos] := (Size shr 8) and $FF; Inc(Pos);
    Frame[Pos] := Size and $FF; Inc(Pos);
  end;

  for i := 0 to 3 do
    Mask[i] := Random(256);

  for i := 0 to 3 do
  begin
    Frame[Pos] := Mask[i];
    Inc(Pos);
  end;

  for i := 0 to Size - 1 do
  begin
    Frame[Pos] := DataBytes[i] xor Mask[i mod 4];
    Inc(Pos);
  end;

  Result := Frame;
end;

function TWebDriverWebSocket.IsSocketError(const ErrorMsg: string): Boolean;
begin
  Result := (Pos('Socket Error', ErrorMsg) > 0) or
            (Pos('EIdSocketError', ErrorMsg) > 0) or
            (Pos('10054', ErrorMsg) > 0) or
            (Pos('10053', ErrorMsg) > 0) or
            (Pos('10061', ErrorMsg) > 0) or
            (Pos('10060', ErrorMsg) > 0);
end;

function TWebDriverWebSocket.IsGracefulDisconnect(const ErrorMsg: string): Boolean;
begin
  Result := (Pos('Connection Closed Gracefully', ErrorMsg) > 0) or
            (Pos('closed gracefully', LowerCase(ErrorMsg)) > 0) or
            (Pos('EIdConnClosedGracefully', ErrorMsg) > 0);
end;

function TWebDriverWebSocket.SafeReadFrame(var Opcode: Byte; var Data: string): Boolean;
var
  B1, B2: Byte;
  Masked: Boolean;
  Len: Int64;
  Mask: array[0..3] of Byte;
  Payload: TIdBytes;
  i: Integer;
begin
  Result := False;
  try
    if FConnection.IOHandler.InputBufferIsEmpty then
    begin
      try
        FConnection.IOHandler.CheckForDataOnSource(10);
        if not FConnection.IOHandler.InputBufferIsEmpty then
          Exit(False);

        if not FConnection.Connected then
          raise EIdConnClosedGracefully.Create('Connection closed');
      except
        on E: Exception do
        begin
          if IsSocketError(E.Message) then
            Exit(False)
          else
            raise;
        end;
      end;
      Exit;
    end;

    B1 := FConnection.IOHandler.ReadByte;
    B2 := FConnection.IOHandler.ReadByte;

    Opcode := B1 and $0F;
    Masked := (B2 and $80) <> 0;
    Len := B2 and $7F;

    if Len = 126 then
      Len := FConnection.IOHandler.ReadUInt16
    else if Len = 127 then
    begin
      FConnection.IOHandler.ReadUInt32;
      Len := FConnection.IOHandler.ReadUInt32;
    end;

    if Masked then
      for i := 0 to 3 do
        Mask[i] := FConnection.IOHandler.ReadByte;

    if Len > 0 then
    begin
      SetLength(Payload, Len);
      FConnection.IOHandler.ReadBytes(Payload, Len, False);

      if Masked then
        for i := 0 to Len - 1 do
          Payload[i] := Payload[i] xor Mask[i mod 4];

      Data := TEncoding.UTF8.GetString(Payload);
    end
    else
      Data := '';

    Result := True;
  except
    on E: EIdConnClosedGracefully do
    begin
      Data := '';
      raise;
    end;
    on E: EIdSocketError do
    begin
      Data := '';
      if FIgnoreSocketErrors then
        Result := False
      else
        raise;
    end;
    on E: Exception do
    begin
      Data := '';
      Result := False;
    end;
  end;
end;

function TWebDriverWebSocket.ReadFrame(var Opcode: Byte; var Data: string): Boolean;
begin
  Result := SafeReadFrame(Opcode, Data);
end;

procedure TWebDriverWebSocket.SafeWriteData(const Data: TIdBytes);
begin
  try
    if CheckConnection then
    begin
      FConnection.IOHandler.Write(Data);
    end;
  except
    on E: EIdSocketError do
    begin
      if not FIgnoreSocketErrors then
        raise;
    end;
    on E: EIdConnClosedGracefully do
    begin
    end;
    on E: Exception do
    begin
      if not IsSocketError(E.Message) then
        raise;
    end;
  end;
end;

function TWebDriverWebSocket.CheckConnection: Boolean;
begin
  FLock.Enter;
  try
    Result := FActive and Assigned(FConnection) and
              FConnection.Connected and not FStopping;
  finally
    FLock.Leave;
  end;
end;

procedure TWebDriverWebSocket.SendPing;
begin
  FLock.Enter;
  try
    if CheckConnection then
    begin
      SafeWriteData(MakeFrame('', $09));
      FLastPingTime := GetTicks;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TWebDriverWebSocket.WorkerLoop;
var
  Opcode: Byte;
  Data: string;
  CurrentTime: UInt64;
  ConnectionClosedGracefully: Boolean;
  SocketErrorOccurred: Boolean;
begin
  ConnectionClosedGracefully := False;
  SocketErrorOccurred := False;
  FLastPingTime := GetTicks;

  while FActive and not FStopping do
  begin
    try
      if not CheckConnection then
      begin
        ConnectionClosedGracefully := True;
        Break;
      end;

      CurrentTime := GetTicks;
      if (CurrentTime - FLastPingTime > FPingInterval) then
      begin
        SendPing;
      end;

      try
        if FConnection.IOHandler.Readable(100) then
        begin
          if ReadFrame(Opcode, Data) then
          begin
            case Opcode of
              $01:
                PostMessage(Data);
              $08:
                begin
                  ConnectionClosedGracefully := True;
                  Break;
                end;
              $09:
                begin
                  FLock.Enter;
                  try
                    if CheckConnection then
                      SafeWriteData(MakeFrame(Data, $0A));
                  finally
                    FLock.Leave;
                  end;
                end;
              $0A:
                begin
                  FLastPingTime := GetTicks;
                end;
              else
            end;
          end;
        end;
      except
        on E: EIdConnClosedGracefully do
        begin
          ConnectionClosedGracefully := True;
          Break;
        end;
        on E: EIdSocketError do
        begin
          SocketErrorOccurred := True;
          if not FIgnoreSocketErrors then
            PostError('[TWebDriverWebSocket.WorkerLoop] Socket Error: ' + E.Message, True);
          Break;
        end;
        on E: Exception do
        begin
          if not IsSocketError(E.Message) then
            PostError('[TWebDriverWebSocket.WorkerLoop] : ' + E.Message);
          Break;
        end;
      end;

      Delay(10);

    except
      on E: Exception do
      begin
        if FActive and not FStopping then
        begin
          if IsGracefulDisconnect(E.Message) then
          begin
            ConnectionClosedGracefully := True;
          end
          else if IsSocketError(E.Message) then
          begin
            SocketErrorOccurred := True;
            if not FIgnoreSocketErrors then
              PostError('[TWebDriverWebSocket.WorkerLoop] : ' + E.Message, True);
          end
          else
          begin
            PostError('[TWebDriverWebSocket.WorkerLoop] : ' + E.Message);
          end;
        end;
        Break;
      end;
    end;
  end;

  if FActive then
  begin
    InternalDisconnect(True);
    if FAutoReconnect and not FStopping then
    begin
      if ConnectionClosedGracefully or
         (SocketErrorOccurred and not FIgnoreSocketErrors) then
      begin
        AttemptReconnect;
      end;
    end;
  end;
end;

procedure TWebDriverWebSocket.AttemptReconnect;
begin
  if FIsReconnecting or FStopping then
    Exit;

  FIsReconnecting := True;

  TThread.Queue(nil,
    procedure
    begin
      if FStopping then
        Exit;

      if FReconnectAttempts < FMaxReconnectAttempts then
      begin
        Inc(FReconnectAttempts);
        try
          Delay(1000 * FReconnectAttempts + Random(500));
          Connect;
        except
          on E: Exception do
          begin
            if not IsSocketError(E.Message) or not FIgnoreSocketErrors then
              PostError('[TWebDriverWebSocket.AttemptReconnect] : ' + E.Message);

            if FReconnectAttempts < FMaxReconnectAttempts then
              AttemptReconnect;
          end;
        end;
      end
      else
      begin
        PostError('[TWebDriverWebSocket] : Max reconnection attempts reached');
      end;
      FIsReconnecting := False;
    end);
end;

procedure TWebDriverWebSocket.StopWorker;
var
  Start: UInt64;
begin
  if Assigned(FWorker) then
  begin
    FWorker.Terminate;

    Start := GetTicks;
    while (GetTicks - Start < 1000) and not FWorker.Finished do
      Delay(10);

    if not FWorker.Finished then
    begin
      FWorker.Terminate;
      FWorker.WaitFor;
    end;

    FreeAndNil(FWorker);
  end;
end;

procedure TWebDriverWebSocket.CloseConnection;
begin
  try
    if Assigned(FConnection) then
    begin
      if FConnection.Connected then
        FConnection.Disconnect(False);
    end;
  except
  end;
end;

procedure TWebDriverWebSocket.InternalDisconnect(FromWorker: Boolean = False);
begin
  if not FActive and not FReady then
    Exit;

  FActive := False;
  FReady := False;

  try
    if not FromWorker then
    begin
      FLock.Enter;
      try
        if Assigned(FConnection) and FConnection.Connected then
        begin
          SafeWriteData(MakeFrame('', $08));
          Delay(50);
        end;
      finally
        FLock.Leave;
      end;
    end;
  except
  end;

  if not FromWorker then
  begin
    StopWorker;
  end;

  CloseConnection;

  PostDisconnect;
end;

procedure TWebDriverWebSocket.Connect;
var
  URI: TIdURI;
  Port: Integer;
begin
  if FActive then
    Exit;

  if FStopping then
    Exit;

  if FIsReconnecting then
    Exit;

  try
    URI := TIdURI.Create(FHost);
    try
      FConnection.Host := URI.Host;

      if URI.Port <> '' then
        Port := StrToIntDef(URI.Port, 80)
      else
        Port := 80;

      FConnection.Port := Port;

      FConnection.ReadTimeout := FReadTimeout;
      FConnection.ConnectTimeout := FConnectionTimeout;

      FConnection.Connect;
      DoHandshake;

      if not CheckHandshake then
      begin
        CloseConnection;
        PostError('[TWebDriverWebSocket.CheckHandshake] : Handshake Failed');
        Exit;
      end;

      FActive := True;
      FReady := True;
      FReconnectAttempts := 0;

      StopWorker;
      FWorker := TWebSocketWorker.Create(Self);

      PostConnect;

    finally
      URI.Free;
    end;
  except
    on E: EIdSocketError do
    begin
      if not FIgnoreSocketErrors then
        PostError('[TWebDriverWebSocket.Connect] Socket Error: ' + E.Message, True);
      raise;
    end;
    on E: Exception do
    begin
      PostError('[TWebDriverWebSocket.Connect] : ' + E.Message);
      raise;
    end;
  end;
end;

procedure TWebDriverWebSocket.Disconnect;
begin
  InternalDisconnect;
end;

procedure TWebDriverWebSocket.WriteData(const Text: string);
begin
  if not CheckConnection then
  begin
    PostError('[TWebDriverWebSocket.WriteData] : Websocket Not Connected');
    Exit;
  end;

  FLock.Enter;
  try
    if CheckConnection then
    begin
      SafeWriteData(MakeFrame(Text, $01));
    end
    else
      PostError('[TWebDriverWebSocket.WriteData] : Connection Lost');
  finally
    FLock.Leave;
  end;
end;

procedure TWebDriverWebSocket.PostMessage(const Text: string);
begin
  if Assigned(FOnMessage) and not FStopping then
    TThread.Queue(nil,
      procedure
      begin
        if not FStopping and Assigned(FOnMessage) then
          FOnMessage(Self, Text);
      end);
end;

procedure TWebDriverWebSocket.PostConnect;
begin
  if Assigned(FOnConnect) and not FStopping then
    TThread.Queue(nil,
      procedure
      begin
        if not FStopping and Assigned(FOnConnect) then
          FOnConnect(Self);
      end);
end;

procedure TWebDriverWebSocket.PostDisconnect;
begin
  if Assigned(FOnDisconnect) and not FStopping then
    TThread.Queue(nil,
      procedure
      begin
        if not FStopping and Assigned(FOnDisconnect) then
          FOnDisconnect(Self);
      end);
end;

procedure TWebDriverWebSocket.PostError(const Text: string; IsSocketError: Boolean = False);
begin
  if IsSocketError and FIgnoreSocketErrors then
    Exit;

  if Assigned(FOnError) and not FStopping then
    TThread.Queue(nil,
      procedure
      begin
        if not FStopping and Assigned(FOnError) then
          FOnError(Self, Text);
      end);
end;

end.
