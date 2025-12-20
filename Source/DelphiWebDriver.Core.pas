{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core;

interface

uses
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Core.Capabilities,
  DelphiWebDriver.Core.Sessions,
  DelphiWebDriver.Core.Classic,
  DelphiWebDriver.Core.BiDi,
  DelphiWebDriver.Core.Events,
  DelphiWebDriver.Core.Server,
  DelphiWebDriver.Types;

type
  TWebDriver = class(TInterfacedObject, IWebDriver)
  private
    FConfig: TWebDriverConfig;
    FCapabilities : IWebDriverCapabilities;
    FSessions : IWebDriverSessions;
    FClassic: IWebDriverClassic;
    FBiDi: IWebDriverBiDi;
    FEvents: IWebDriverEvents;
    FServer: IWebDriverServer;
  public
    constructor Create(Config: TWebDriverConfig); virtual;
    function Capabilities: IWebDriverCapabilities;
    function Sessions : IWebDriverSessions;
    function Classic : IWebDriverClassic;
    function BiDi : IWebDriverBiDi;
    function Events : IWebDriverEvents;
    function Server : IWebDriverServer;
    function Config : TWebDriverConfig;
  end;

implementation

{ TWebDriver }

constructor TWebDriver.Create(Config: TWebDriverConfig);
begin
  inherited Create;
  FConfig := Config;
end;

function TWebDriver.BiDi: IWebDriverBiDi;
begin
  if FBiDi = nil then
    FBiDi := TWebDriverBiDi.Create(Self as IWebDriver);
  Result := FBiDi;
end;

function TWebDriver.Config: TWebDriverConfig;
begin
  Result := FConfig;
end;

function TWebDriver.Capabilities: IWebDriverCapabilities;
begin
  if FCapabilities = nil then
    FCapabilities := TWebDriverCapabilities.Create(Self as IWebDriver);
  Result := FCapabilities;
end;

function TWebDriver.Classic: IWebDriverClassic;
begin
  if FClassic = nil then
    FClassic := TWebDriverClassic.Create(Self as IWebDriver);
  Result := FClassic;
end;

function TWebDriver.Events: IWebDriverEvents;
begin
  if FEvents = nil then
    FEvents := TWebDriverEvents.Create;
  Result := FEvents;
end;

function TWebDriver.Server: IWebDriverServer;
begin
  if FServer = nil then
    FServer := TWebDriverServer.Create(Self as IWebDriver);
  Result := FServer;
end;

function TWebDriver.Sessions: IWebDriverSessions;
begin
  if FSessions = nil then
    FSessions := TWebDriverSessions.Create(Self as IWebDriver);
  Result := FSessions;
end;

end.
