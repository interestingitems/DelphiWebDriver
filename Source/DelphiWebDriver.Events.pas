{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Events;

interface

uses
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebDriverEvents = class(TInterfacedObject,
                           IWebDriverEvents,
                           IWebDriverEventsInternal)
  private
    FOnLoadStart: TWebDriverLoadStartEvent;
    FOnLoadComplete: TWebDriverLoadCompleteEvent;
    FOnError: TWebDriverErrorEvent;
    function GetOnLoadStart: TWebDriverLoadStartEvent;
    procedure SetOnLoadStart(const Callback: TWebDriverLoadStartEvent);
    procedure SetOnLoadComplete(const Callback: TWebDriverLoadCompleteEvent);
    function GetOnLoadComplete: TWebDriverLoadCompleteEvent;
    function GetOnError: TWebDriverErrorEvent;
    procedure SetOnError(const Callback: TWebDriverErrorEvent);
  public
    property OnLoadStart: TWebDriverLoadStartEvent read GetOnLoadStart write SetOnLoadStart;
    property OnLoadComplete: TWebDriverLoadCompleteEvent read GetOnLoadComplete write SetOnLoadComplete;
    property OnError: TWebDriverErrorEvent read GetOnError write SetOnError;
    procedure TriggerLoadStart;
    procedure TriggerLoadComplete;
    procedure TriggerError(const Error: string);
  end;

implementation

{ TWebDriverEvents }

function TWebDriverEvents.GetOnError: TWebDriverErrorEvent;
begin
  Result := FOnError;
end;

function TWebDriverEvents.GetOnLoadComplete: TWebDriverLoadCompleteEvent;
begin
  Result := FOnLoadComplete;
end;

function TWebDriverEvents.GetOnLoadStart: TWebDriverLoadStartEvent;
begin
  Result := FOnLoadStart;
end;

procedure TWebDriverEvents.SetOnError(const Callback: TWebDriverErrorEvent);
begin
  FOnError := Callback;
end;

procedure TWebDriverEvents.SetOnLoadComplete(const Callback: TWebDriverLoadCompleteEvent);
begin
  FOnLoadComplete := Callback;
end;

procedure TWebDriverEvents.SetOnLoadStart(const Callback: TWebDriverLoadStartEvent);
begin
  FOnLoadStart := Callback;
end;

procedure TWebDriverEvents.TriggerError(const Error: string);
begin
  if Assigned(FOnError) then
    FOnError(Error);
end;

procedure TWebDriverEvents.TriggerLoadComplete;
begin
  if Assigned(FOnLoadComplete) then
    FOnLoadComplete;
end;

procedure TWebDriverEvents.TriggerLoadStart;
begin
  if Assigned(FOnLoadStart) then
    FOnLoadStart;
end;

end.
