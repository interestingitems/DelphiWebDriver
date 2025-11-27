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
    FOnLoadComplete: TWebDriverLoadEvent;
    procedure SetOnLoadComplete(const Callback: TWebDriverLoadEvent);
    function GetOnLoadComplete: TWebDriverLoadEvent;
  public
    property OnLoadComplete: TWebDriverLoadEvent read GetOnLoadComplete write SetOnLoadComplete;
    procedure TriggerLoadComplete;
  end;

implementation

{ TWebDriverEvents }

function TWebDriverEvents.GetOnLoadComplete: TWebDriverLoadEvent;
begin
  Result := FOnLoadComplete;
end;

procedure TWebDriverEvents.SetOnLoadComplete(const Callback: TWebDriverLoadEvent);
begin
  FOnLoadComplete := Callback;
end;

procedure TWebDriverEvents.TriggerLoadComplete;
begin
  if Assigned(FOnLoadComplete) then
    FOnLoadComplete;
end;

end.
