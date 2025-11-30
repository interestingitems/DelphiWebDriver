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
    function GetOnError: TWebDriverErrorEvent;
    procedure SetOnError(const Callback: TWebDriverErrorEvent);
  public
    property OnError: TWebDriverErrorEvent read GetOnError write SetOnError;
    procedure TriggerError(const Error: string);
  end;

implementation

{ TWebDriverEvents }

function TWebDriverEvents.GetOnError: TWebDriverErrorEvent;
begin
  Result := FOnError;
end;

procedure TWebDriverEvents.SetOnError(const Callback: TWebDriverErrorEvent);
begin
  FOnError := Callback;
end;

procedure TWebDriverEvents.TriggerError(const Error: string);
begin
  if Assigned(FOnError) then
    FOnError(Error);
end;

end.
