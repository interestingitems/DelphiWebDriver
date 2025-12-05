{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.Events;

interface

uses
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebDriverEvents = class(TInterfacedObject,
                           IWebDriverEvents,
                           IWebDriverEventsInternal)
  private
    FOnError: TWebDriverErrorEvent;
    FOnBiDiMessage: TWebDriverBiDiMessageEvent;
    function GetOnError: TWebDriverErrorEvent;
    procedure SetOnError(const Callback: TWebDriverErrorEvent);
    function GetOnBiDiMessage: TWebDriverBiDiMessageEvent;
    procedure SetOnBiDiMessage(const Callback: TWebDriverBiDiMessageEvent);
  public
    property OnError: TWebDriverErrorEvent read GetOnError write SetOnError;
    property OnBiDiMessage: TWebDriverBiDiMessageEvent read GetOnBiDiMessage write SetOnBiDiMessage;
    procedure TriggerError(const Error: string);
    procedure TriggerBiDiMessage(const Msg: string);
  end;

implementation

{ TWebDriverEvents }

function TWebDriverEvents.GetOnBiDiMessage: TWebDriverBiDiMessageEvent;
begin
  Result := FOnBiDiMessage;
end;

function TWebDriverEvents.GetOnError: TWebDriverErrorEvent;
begin
  Result := FOnError;
end;

procedure TWebDriverEvents.SetOnBiDiMessage(const Callback: TWebDriverBiDiMessageEvent);
begin
  FOnBiDiMessage := Callback;
end;

procedure TWebDriverEvents.SetOnError(const Callback: TWebDriverErrorEvent);
begin
  FOnError := Callback;
end;

procedure TWebDriverEvents.TriggerBiDiMessage(const Msg: string);
begin
  if Assigned(FOnBiDiMessage) then
    FOnBiDiMessage(Msg);
end;

procedure TWebDriverEvents.TriggerError(const Error: string);
begin
  if Assigned(FOnError) then
    FOnError(Error);
end;

end.
