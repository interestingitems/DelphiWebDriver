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
  System.DateUtils,
  System.Generics.Collections,
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
    procedure ProcessIncomingMessage(const Msg: string);
    function SafeGetArray(JSON: TJSONObject; const Key: string): TJSONArray;
    function SafeGetInt64(JSON: TJSONObject; const Key: string; Default: Int64 = 0): Int64;
    function SafeGetString(JSON: TJSONObject; const Key: string; Default: string = ''): string;
    procedure ParseConsoleLog(const EventData: TJSONObject);
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
    procedure SubscribeToConsoleEvents;
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
  ProcessIncomingMessage(Msg);
end;

function TWebDriverBiDiCommands.SafeGetString(JSON: TJSONObject; const Key: string; Default: string = ''): string;
var
  Val: TJSONValue;
begin
  Result := Default;
  if not Assigned(JSON) then Exit;

  Val := JSON.GetValue(Key);
  if Assigned(Val) and (Val is TJSONString) then
    Result := TJSONString(Val).Value;
end;

function TWebDriverBiDiCommands.SafeGetInt64(JSON: TJSONObject; const Key: string; Default: Int64 = 0): Int64;
var
  Val: TJSONValue;
begin
  Result := Default;
  if not Assigned(JSON) then Exit;

  Val := JSON.GetValue(Key);
  if Assigned(Val) and (Val is TJSONNumber) then
    Result := TJSONNumber(Val).AsInt64;
end;

function TWebDriverBiDiCommands.SafeGetArray(JSON: TJSONObject; const Key: string): TJSONArray;
var
  Val: TJSONValue;
begin
  Result := nil;
  if not Assigned(JSON) then Exit;

  Val := JSON.GetValue(Key);
  if Assigned(Val) and (Val is TJSONArray) then
    Result := TJSONArray(Val);
end;

procedure TWebDriverBiDiCommands.ParseConsoleLog(const EventData: TJSONObject);
var
  Text, LevelStr, MethodStr, SourceContext, SourceRealm, SourceTypeStr: string;
  Timestamp: Int64;
  TimestampDT: TDateTime;
  Args, CallFrames: TJSONArray;
  SourceObj, StackTraceObj: TJSONObject;
  i: Integer;
  ArgsString, StackString: string;
  ConsoleMessage: TWebDriverConsoleMessage;
  ArgType, ArgValue, ArgInternalId, ArgHandle, ArgSharedId: string;
  LogSourceStr, URL: string;
  LineNumber, ColumnNumber: Integer;
begin
  try
    Text := SafeGetString(EventData, 'text');
    LevelStr := SafeGetString(EventData, 'level', 'info');
    MethodStr := SafeGetString(EventData, 'method', 'log');
    Timestamp := SafeGetInt64(EventData, 'timestamp', 0);

    ConsoleMessage.Level := TWebDriverConsoleLogLevel.ToConsoleLogLevel(LevelStr);
    ConsoleMessage.Method := TWebDriverConsoleMethod.ToConsoleMethod(MethodStr);

    if Timestamp > 0 then
      TimestampDT := UnixToDateTime(Timestamp div 1000, False)
    else
      TimestampDT := Now;
    ConsoleMessage.Timestamp := TimestampDT;

    SourceContext := '';
    SourceRealm := '';
    SourceTypeStr := '';
    SourceObj := EventData.GetValue('source') as TJSONObject;
    if Assigned(SourceObj) then
    begin
      SourceContext := SafeGetString(SourceObj, 'context');
      SourceRealm := SafeGetString(SourceObj, 'realm');
      SourceTypeStr := SafeGetString(SourceObj, 'type', 'window');
    end;
    ConsoleMessage.SourceContext := SourceContext;
    ConsoleMessage.SourceRealm := SourceRealm;
    ConsoleMessage.SourceType := SourceTypeStr;

    LogSourceStr := SafeGetString(EventData, 'source');
    ConsoleMessage.Source := TWebDriverLogSourceType.ToLogSourceType(LogSourceStr);

    Args := SafeGetArray(EventData, 'args');
    ArgsString := '';
    if Assigned(Args) and (Args.Count > 0) then
    begin
      for i := 0 to Args.Count - 1 do
      begin
        var Arg := Args.Items[i] as TJSONObject;
        if Assigned(Arg) then
        begin
          ArgType := SafeGetString(Arg, 'type');
          ArgValue := SafeGetString(Arg, 'value');
          ArgInternalId := SafeGetString(Arg, 'internalId');
          ArgHandle := SafeGetString(Arg, 'handle');
          ArgSharedId := SafeGetString(Arg, 'sharedId');

          if ArgsString <> '' then
            ArgsString := ArgsString + ', ';

          if SameText(ArgType, 'string') then
            ArgsString := ArgsString + '"' + ArgValue + '"'
          else if SameText(ArgType, 'number') then
            ArgsString := ArgsString + ArgValue
          else if SameText(ArgType, 'boolean') then
            ArgsString := ArgsString + ArgValue
          else if SameText(ArgType, 'undefined') then
            ArgsString := ArgsString + 'undefined'
          else if SameText(ArgType, 'null') then
            ArgsString := ArgsString + 'null'
          else if SameText(ArgType, 'object') then
          begin
            if ArgValue <> '' then
              ArgsString := ArgsString + ArgValue
            else
              ArgsString := ArgsString + 'Object';
          end
          else if SameText(ArgType, 'array') then
            ArgsString := ArgsString + 'Array[' + ArgValue + ']'
          else if SameText(ArgType, 'function') then
            ArgsString := ArgsString + 'function ' + ArgValue + '()'
          else
            ArgsString := ArgsString + ArgValue;

          if ArgInternalId <> '' then
            ArgsString := ArgsString + '{internalId:' + ArgInternalId + '}';
          if ArgHandle <> '' then
            ArgsString := ArgsString + '{handle:' + ArgHandle + '}';
          if ArgSharedId <> '' then
            ArgsString := ArgsString + '{sharedId:' + ArgSharedId + '}';
        end;
      end;
    end;

    if (Text = '') and (ArgsString <> '') then
      Text := ArgsString;
    ConsoleMessage.Text := Text;

    ConsoleMessage.ArgumentsJSON := Args;
    ConsoleMessage.ArgumentsText := ArgsString;

    ConsoleMessage.LineNumber := -1;
    ConsoleMessage.ColumnNumber := -1;
    ConsoleMessage.URL := '';
    ConsoleMessage.WorkerId := '';
    ConsoleMessage.IsInternal := False;

    StackString := '';
    StackTraceObj := EventData.GetValue('stackTrace') as TJSONObject;
    if Assigned(StackTraceObj) then
    begin
      CallFrames := StackTraceObj.GetValue('callFrames') as TJSONArray;
      if Assigned(CallFrames) and (CallFrames.Count > 0) then
      begin
        var FirstFrame := CallFrames.Items[0] as TJSONObject;
        if Assigned(FirstFrame) then
        begin
          ConsoleMessage.LineNumber := SafeGetInt64(FirstFrame, 'lineNumber', 0);
          ConsoleMessage.ColumnNumber := SafeGetInt64(FirstFrame, 'columnNumber', 0);
          ConsoleMessage.URL := SafeGetString(FirstFrame, 'url');
          ConsoleMessage.WorkerId := SafeGetString(FirstFrame, 'workerId');

          var FunctionName := SafeGetString(FirstFrame, 'functionName', '');
          ConsoleMessage.IsInternal := (FunctionName = '') or
            (Pos('native', FunctionName) > 0) or
            (Pos('anonymous', FunctionName) > 0);
        end;

        for i := 0 to CallFrames.Count - 1 do
        begin
          var Frame := CallFrames.Items[i] as TJSONObject;
          if Assigned(Frame) then
          begin
            var FunctionName := SafeGetString(Frame, 'functionName', '(anonymous)');
            URL := SafeGetString(Frame, 'url');
            LineNumber := SafeGetInt64(Frame, 'lineNumber', 0) + 1;
            ColumnNumber := SafeGetInt64(Frame, 'columnNumber', 0) + 1;

            if URL <> '' then
            begin
              var FileName := ExtractFileName(URL);
              StackString := StackString + sLineBreak + Format('    at %s (%s:%d:%d)',
                [FunctionName, FileName, LineNumber, ColumnNumber]);
            end
            else
            begin
              StackString := StackString + sLineBreak + Format('    at %s (unknown source)', [FunctionName]);
            end;
          end;
        end;
      end;
    end;
    ConsoleMessage.StackTrace := StackString;

    (FDriver.Events as IWebDriverEventsInternal).TriggerBidiConsoleMessage(ConsoleMessage);

  except
    on E: Exception do
    begin
      (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverBiDiCommands.ParseConsoleLog] : ' + E.Message);
    end;
  end;
end;

procedure TWebDriverBiDiCommands.ProcessIncomingMessage(const Msg: string);
var
  JSONData: TJSONObject;
  Method, TypeStr: string;
  Params: TJSONObject;
begin
  try
    JSONData := TJSONObject.ParseJSONValue(Msg) as TJSONObject;
    if not Assigned(JSONData) then
      Exit;

    try
      if JSONData.TryGetValue<string>('method', Method) then
      begin
        if JSONData.TryGetValue<TJSONObject>('params', Params) then
        begin
          if Method = 'log.entryAdded' then
            begin
              TypeStr := SafeGetString(Params, 'type');
              if TypeStr = 'console' then
                ParseConsoleLog(Params);
            end;
        end;
      end;

    finally
      JSONData.Free;
    end;
  except
    on E: Exception do
    begin
      (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverBiDiCommands.ProcessIncomingMessage] : ' + E.Message);
    end;
  end;
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

procedure TWebDriverBiDiCommands.SubscribeToConsoleEvents;
begin
  Subscribe(['log.entryAdded']);
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
