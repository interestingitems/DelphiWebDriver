{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.BiDi;

interface

uses
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Core.BiDi.Commands,
  DelphiWebDriver.Types;

type
  TWebDriverBiDi = class(TInterfacedObject, IWebDriverBiDi)
  private
    [weak]
    FDriver: IWebDriver;
    FCommands: IWebDriverBiDiCommands;
  public
    constructor Create(ADriver: IWebDriver);
    function Commands: IWebDriverBiDiCommands;
  end;

implementation

{ TWebDriverBiDi }

function TWebDriverBiDi.Commands: IWebDriverBiDiCommands;
begin
  if FCommands = nil then
    FCommands := TWebDriverBiDiCommands.Create(FDriver);
  Result := FCommands;
end;

constructor TWebDriverBiDi.Create(ADriver: IWebDriver);
begin
  inherited Create;
  FDriver := ADriver;
end;

end.
