{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.Server;

interface

uses
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types,
  System.SysUtils,
  System.IOUtils
{$IFDEF POSIX}
  , Posix.Unistd
  , Posix.SysTypes
  , Posix.SysWait
  , Posix.Signal
{$ENDIF}
{$IFDEF MSWINDOWS}
  , Winapi.Windows
{$ENDIF}
  ;

type
  TWebDriverServer = class(TInterfacedObject, IWebDriverServer)
  private
    [weak]
    FDriver: IWebDriver;
    FPort: Integer;
    FStarted: Boolean;
    {$IFDEF MSWINDOWS}
    FProcessInfo: TProcessInformation;
    {$ENDIF}
    {$IFDEF POSIX}
    FPID: pid_t;
    {$ENDIF}
  public
    constructor Create(ADriver: IWebDriver);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function GetBaseURL: string;
  end;

implementation

{ TWebDriverServer }

constructor TWebDriverServer.Create(ADriver: IWebDriver);
begin
  inherited Create;
  FDriver := ADriver;
  FStarted := False;
  {$IFDEF POSIX}
  FPID := 0;
  {$ENDIF}
end;

destructor TWebDriverServer.Destroy;
begin
  Stop;
  inherited;
end;

function TWebDriverServer.GetBaseURL: string;
begin
  if FStarted then
    Result := 'http://localhost:' + FPort.ToString;
end;

procedure TWebDriverServer.Start;
{$IFDEF POSIX}
var
  PID: pid_t;
  ArgV: array[0..2] of PAnsiChar;
{$ENDIF}
var
  Cmd, DriverExecutablePath: string;
begin
  if FStarted then
    Exit;

  if Not FDriver.Config.DriverPath.IsEmpty then
    begin
      if not TFile.Exists(FDriver.Config.DriverPath) then
        begin
          (FDriver.Events as IWebDriverEventsInternal).TriggerError('WebDriver executable not found: ' + FDriver.Config.DriverPath);
          Exit;
        end
      else
        DriverExecutablePath := FDriver.Config.DriverPath;
    end
  else
    begin
      DriverExecutablePath := TPath.Combine(ExtractFilePath(ParamStr(0)), FDriver.Config.Browser.DriverName);
      if not TFile.Exists(DriverExecutablePath) then
        begin
          (FDriver.Events as IWebDriverEventsInternal).TriggerError('WebDriver executable not found: ' + DriverExecutablePath);
          Exit;
        end;
    end;

  Cmd := DriverExecutablePath + ' --port=' + FDriver.Config.ServerPort.ToString;

  {$IFDEF MSWINDOWS}
  var SI: TStartupInfo;
  ZeroMemory(@SI, SizeOf(SI));
  ZeroMemory(@FProcessInfo, SizeOf(FProcessInfo));
  SI.cb := SizeOf(SI);

  if not CreateProcess(nil, PChar(Cmd), nil, nil, False, CREATE_NO_WINDOW,
                      nil, nil, SI, FProcessInfo) then
    begin
      (FDriver.Events as IWebDriverEventsInternal).TriggerError('Cannot start driver: ' + SysErrorMessage(GetLastError));
      Exit;
    end;
  {$ENDIF}

  {$IFDEF POSIX}
  ArgV[0] := PAnsiChar(AnsiString(DriverExecutablePath));
  ArgV[1] := PAnsiChar(AnsiString('--port=' + Port.ToString));
  ArgV[2] := nil;

  PID := fork;
  if PID = -1 then
    begin
      (FDriver.Events as IWebDriverEventsInternal).TriggerError('fork() failed');
      Exit;
    end;

  if PID = 0 then
  begin
    execvp(ArgV[0], @ArgV[0]);
    _exit(127);
  end;

  FPID := PID;
  {$ENDIF}

  FStarted := True;
  FPort := FDriver.Config.ServerPort;
  Sleep(500);
end;

procedure TWebDriverServer.Stop;
begin
  if not FStarted then
    Exit;

  {$IFDEF MSWINDOWS}
  if FProcessInfo.hProcess <> 0 then
  begin
    if WaitForSingleObject(FProcessInfo.hProcess, 1500) = WAIT_TIMEOUT then
      TerminateProcess(FProcessInfo.hProcess, 0);

    WaitForSingleObject(FProcessInfo.hProcess, 500);
    CloseHandle(FProcessInfo.hProcess);
    CloseHandle(FProcessInfo.hThread);

    FProcessInfo.hProcess := 0;
    FProcessInfo.hThread := 0;
  end;
  {$ENDIF}

  {$IFDEF POSIX}
  if FPID > 0 then
  begin
    kill(FPID, SIGTERM);
    Sleep(300);

    if kill(FPID, 0) = 0 then
      kill(FPID, SIGKILL);

    waitpid(FPID, nil, 0);

    FPID := 0;
  end;
  {$ENDIF}

  FStarted := False;

end;

end.

