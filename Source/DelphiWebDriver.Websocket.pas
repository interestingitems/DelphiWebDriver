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
    procedure PostError(const Text: string);
    function GetTicks: UInt64;
    procedure Delay(MS: Cardinal);
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
  InitConnection;
end;

destructor TWebDriverWebSocket.Destroy;
begin
  FStopping := True;
  Disconnect;
  FLock.Free;
  FConnection.Free;
  inherited;
end;

function TWebDriverWebSocket.GetTicks: UInt64;
begin
  {$IFDEF MSWINDOWS}
  Result := GetTickCount;
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
  FConnection.ReadTimeout := 1000;
  FConnection.ConnectTimeout := 5000;
  FConnection.Intercept := nil;
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

function TWebDriverWebSocket.ReadFrame(var Opcode: Byte; var Data: string): Boolean;
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
      Exit;

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
    Data := '';
  end;
end;

procedure TWebDriverWebSocket.WorkerLoop;
var
  Opcode: Byte;
  Data: string;
begin
  while FActive and not FStopping do
  begin
    try
      if not FConnection.Connected then
        Break;

      if FConnection.IOHandler.Readable(100) then
      begin
        if ReadFrame(Opcode, Data) then
        begin
          case Opcode of
            $01:
              PostMessage(Data);
            $08:
              Break;
            $09:
              begin
                FLock.Enter;
                try
                  if FActive and FConnection.Connected and not FStopping then
                    FConnection.IOHandler.Write(MakeFrame(Data, $0A));
                finally
                  FLock.Leave;
                end;
              end;
            $0A:
              ;
            else
          end;
        end;
      end
      else
      begin
        Delay(10);
      end;
    except
      on E: Exception do
      begin
        if FActive and not FStopping then
          PostError('[TWebDriverWebSocket.WorkerLoop] : ' + E.Message);
        Break;
      end;
    end;
  end;

  if FActive then
  begin
    TThread.Queue(nil,
      procedure
      begin
        if not FStopping then
          Disconnect;
      end);
  end;
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
      Delay(100);
    end;

    FreeAndNil(FWorker);
  end;
end;

procedure TWebDriverWebSocket.CloseConnection;
begin
  try
    if Assigned(FConnection) and FConnection.Connected then
      FConnection.Disconnect;
  except
  end;
end;

procedure TWebDriverWebSocket.Connect;
var
  URI: TIdURI;
  Port: Integer;
begin
  if FActive then
  begin
    Exit;
  end;

  if FStopping then
  begin
    Exit;
  end;

  URI := TIdURI.Create(FHost);
  try
    FConnection.Host := URI.Host;

    if URI.Port <> '' then
      Port := StrToIntDef(URI.Port, 80)
    else
      Port := 80;

    FConnection.Port := Port;
    FConnection.Connect;
    DoHandshake;

    if not CheckHandshake then
    begin
      CloseConnection;
      PostError('[TWebDriverWebSocket.CheckHandshake] : Handshake Failed');
    end;

    FActive := True;
    FReady := True;

    StopWorker;
    FWorker := TWebSocketWorker.Create(Self);

    PostConnect;

  finally
    URI.Free;
  end;
end;

procedure TWebDriverWebSocket.Disconnect;
begin
  if not FActive and not FReady then
    Exit;

  FActive := False;
  FReady := False;

  try
    if FReady then
    begin
      FLock.Enter;
      try
        if Assigned(FConnection) and FConnection.Connected then
        begin
          FConnection.IOHandler.Write(MakeFrame('', $08));
          Delay(50);
        end;
      finally
        FLock.Leave;
      end;
    end;
  except
  end;

  StopWorker;
  CloseConnection;

  PostDisconnect;
end;

procedure TWebDriverWebSocket.WriteData(const Text: string);
begin
  if not FActive or not FReady or FStopping then
    PostError('[TWebDriverWebSocket.WriteData] : Websocket Not Connected');

  FLock.Enter;
  try
    if FActive and Assigned(FConnection) and FConnection.Connected then
    begin
      FConnection.IOHandler.Write(MakeFrame(Text, $01));
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

procedure TWebDriverWebSocket.PostError(const Text: string);
begin
  if Assigned(FOnError) and not FStopping then
    TThread.Queue(nil,
      procedure
      begin
        if not FStopping and Assigned(FOnError) then
          FOnError(Self, Text);
      end);
end;

end.
