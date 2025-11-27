{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Events;

interface

uses
  System.JSON,
  System.Generics.Collections,
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebDriverEvents = class(TInterfacedObject,
                           IWebDriverEvents,
                           IWebDriverEventsInternal)
  private
    FOnLoadStart: TWebDriverLoadStartEvent;
    FOnLoadComplete: TWebDriverLoadCompleteEvent;
    function GetOnLoadStart: TWebDriverLoadStartEvent;
    procedure SetOnLoadStart(const Callback: TWebDriverLoadStartEvent);
    procedure SetOnLoadComplete(const Callback: TWebDriverLoadCompleteEvent);
    function GetOnLoadComplete: TWebDriverLoadCompleteEvent;
  public
    property OnLoadStart: TWebDriverLoadStartEvent read GetOnLoadStart write SetOnLoadStart;
    property OnLoadComplete: TWebDriverLoadCompleteEvent read GetOnLoadComplete write SetOnLoadComplete;
    procedure TriggerLoadStart;
    procedure TriggerLoadComplete;
  end;

implementation

{ TWebDriverEvents }

function TWebDriverEvents.GetOnLoadComplete: TWebDriverLoadCompleteEvent;
begin
  Result := FOnLoadComplete;
end;

function TWebDriverEvents.GetOnLoadStart: TWebDriverLoadStartEvent;
begin
  Result := FOnLoadStart;
end;

procedure TWebDriverEvents.SetOnLoadComplete(const Callback: TWebDriverLoadCompleteEvent);
begin
  FOnLoadComplete := Callback;
end;

procedure TWebDriverEvents.SetOnLoadStart(const Callback: TWebDriverLoadStartEvent);
begin
  FOnLoadStart := Callback;
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
