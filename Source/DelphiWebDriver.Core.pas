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
  DelphiWebDriver.Core.Events,
  DelphiWebDriver.Types;

type
  TWebDriver = class(TInterfacedObject, IWebDriver)
  private
    FBaseUrl: string;
    FBrowserConfig: TWebDriverBrowserConfig;
    FCapabilities : IWebDriverCapabilities;
    FSessions : IWebDriverSessions;
    FClassic: IWebDriverClassic;
    FEvents: IWebDriverEvents;
  public
    constructor Create(BrowserConfig: TWebDriverBrowserConfig; const ABaseUrl: string); virtual;
    function Capabilities: IWebDriverCapabilities;
    function Sessions : IWebDriverSessions;
    function Classic : IWebDriverClassic;
    function Events : IWebDriverEvents;
    function BrowserConfig : TWebDriverBrowserConfig;
  end;

implementation

{ TWebDriver }

constructor TWebDriver.Create(BrowserConfig: TWebDriverBrowserConfig; const ABaseUrl: string);
begin
  inherited Create;
  FBaseUrl := ABaseUrl;
  FBrowserConfig := BrowserConfig;
end;

function TWebDriver.BrowserConfig: TWebDriverBrowserConfig;
begin
  Result := FBrowserConfig;
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
    FClassic := TWebDriverClassic.Create(Self as IWebDriver, FBaseUrl);
  Result := FClassic;
end;

function TWebDriver.Events: IWebDriverEvents;
begin
  if FEvents = nil then
    FEvents := TWebDriverEvents.Create;
  Result := FEvents;
end;

function TWebDriver.Sessions: IWebDriverSessions;
begin
  if FSessions = nil then
    FSessions := TWebDriverSessions.Create(Self as IWebDriver);
  Result := FSessions;
end;

end.
