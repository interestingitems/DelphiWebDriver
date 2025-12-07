{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.Classic;

interface

uses
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Core.Classic.Navigation,
  DelphiWebDriver.Core.Classic.Contexts,
  DelphiWebDriver.Core.Classic.Cookies,
  DelphiWebDriver.Core.Classic.Elements,
  DelphiWebDriver.Core.Classic.Commands,
  DelphiWebDriver.Core.Classic.Document,
  DelphiWebDriver.Core.Classic.Wait,
  DelphiWebDriver.Core.Classic.Screenshot,
  DelphiWebDriver.Core.Classic.Alert,
  DelphiWebDriver.Core.Classic.Actions,
  DelphiWebDriver.Core.Classic.Timeouts,
  DelphiWebDriver.Types;

type
  TWebDriverClassic = class(TInterfacedObject, IWebDriverClassic)
  private
    [weak]
    FDriver: IWebDriver;
    FBaseUrl : string;
    FNavigation : IWebDriverNavigation;
    FContexts : IWebDriverContexts;
    FElements : IWebDriverElements;
    FCookies: IWebDriverCookies;
    FCommands: IWebDriverCommands;
    FDocument : IWebDriverDocument;
    FWait : IWebDriverWait;
    FScreenshot : IWebDriverScreenshot;
    FAlert : IWebDriverAlert;
    FActions : IWebDriverActions;
    FTimeouts: IWebDriverTimeouts;
  public
    constructor Create(ADriver: IWebDriver);
    function Navigation : IWebDriverNavigation;
    function Contexts : IWebDriverContexts;
    function Elements : IWebDriverElements;
    function Cookies: IWebDriverCookies;
    function Commands: IWebDriverCommands;
    function Document : IWebDriverDocument;
    function Wait : IWebDriverWait;
    function Screenshot : IWebDriverScreenshot;
    function Alert : IWebDriverAlert;
    function Actions : IWebDriverActions;
    function Timeouts : IWebDriverTimeouts;
  end;

implementation

{ TWebDriverClassic }

constructor TWebDriverClassic.Create(ADriver: IWebDriver);
begin
  inherited Create;
  FDriver := ADriver;
  FBaseUrl := FDriver.Server.GetBaseURL;
end;

function TWebDriverClassic.Timeouts: IWebDriverTimeouts;
begin
  if FTimeouts = nil then
    FTimeouts := TWebDriverTimeouts.Create(FDriver);
  Result := FTimeouts;
end;

function TWebDriverClassic.Navigation: IWebDriverNavigation;
begin
  if FNavigation = nil then
    FNavigation := TWebDriverNavigation.Create(FDriver);
  Result := FNavigation;
end;

function TWebDriverClassic.Commands: IWebDriverCommands;
begin
  if FCommands = nil then
    FCommands := TWebDriverCommands.Create(FDriver, FBaseUrl);
  Result := FCommands;
end;

function TWebDriverClassic.Contexts: IWebDriverContexts;
begin
  if FContexts = nil then
    FContexts := TWebDriverContexts.Create(FDriver);
  Result := FContexts;
end;

function TWebDriverClassic.Cookies: IWebDriverCookies;
begin
  if FCookies = nil then
    FCookies := TWebDriverCookies.Create(FDriver);
  Result := FCookies;
end;

function TWebDriverClassic.Screenshot: IWebDriverScreenshot;
begin
  if FScreenshot = nil then
    FScreenshot := TWebDriverScreenshot.Create(FDriver);
  Result := FScreenshot;
end;

function TWebDriverClassic.Wait: IWebDriverWait;
begin
  if FWait = nil then
    FWait := TWebDriverWait.Create(FDriver);
  Result := FWait;
end;

function TWebDriverClassic.Elements: IWebDriverElements;
begin
  if FElements = nil then
    FElements := TWebDriverElements.Create(FDriver);
  Result := FElements;
end;

function TWebDriverClassic.Document: IWebDriverDocument;
begin
  if FDocument = nil then
    FDocument := TWebDriverDocument.Create(FDriver);
  Result := FDocument;
end;

function TWebDriverClassic.Actions: IWebDriverActions;
begin
  if FActions = nil then
    FActions := TWebDriverActions.Create(FDriver);
  Result := FActions;
end;

function TWebDriverClassic.Alert: IWebDriverAlert;
begin
  if FAlert = nil then
    FAlert := TWebDriverAlert.Create(FDriver);
  Result := FAlert;
end;


end.
