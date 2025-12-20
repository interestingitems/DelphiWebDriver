{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Types;

interface

uses
  System.SysUtils,
  System.JSON;

type
  TWebDriverConsoleLogLevel = (cllVerbose, cllDebug, cllInfo, cllLog, cllWarning, cllError, cllCritical);
  TWebDriverConsoleLogLevelHelper = record Helper for TWebDriverConsoleLogLevel
    class function ToConsoleLogLevel(const Str: string): TWebDriverConsoleLogLevel; static;
    function ToString: string;
  end;

  TWebDriverConsoleMethod = (cmLog, cmDebug, cmInfo, cmWarn, cmError, cmAssert, cmTrace, cmClear, cmDir, cmDirXML,
                             cmTable, cmGroup, cmGroupCollapsed, cmGroupEnd, cmCount, cmCountReset, cmTime, cmTimeLog,
                             cmTimeEnd, cmTimeStamp, cmProfile, cmProfileEnd, cmMemory, cmUnknown);
  TWebDriverConsoleMethodHelper = record Helper for TWebDriverConsoleMethod
    class function ToConsoleMethod(const Str: string): TWebDriverConsoleMethod; static;
    function ToString: string;
  end;

  TWebDriverLogSourceType = (lstXML, lstJavaScript, lstNetwork, lstConsoleAPI, lstStorage, lstAppCache, lstRendering,
                             lstSecurity, lstDeprecation, lstWorker, lstViolation, lstIntervention, lstRecommendation,lstOther);
  TWebDriverLogSourceTypeHelper = record Helper for TWebDriverLogSourceType
    class function ToLogSourceType(const Str: string): TWebDriverLogSourceType; static;
    function ToString: string;
  end;

  TWebDriverConsoleMessage = record
    Text: string;
    Level: TWebDriverConsoleLogLevel;
    Method: TWebDriverConsoleMethod;
    Timestamp: TDateTime;
    SourceContext: string;
    SourceRealm: string;
    SourceType: string;
    ArgumentsJSON: TJSONArray;
    ArgumentsText: string;
    StackTrace: string;
    Source: TWebDriverLogSourceType;
    LineNumber: Integer;
    ColumnNumber: Integer;
    URL: string;
    WorkerId: string;
    IsInternal: Boolean;
  end;

  TWebDriverErrorEvent = reference to procedure(const Error: string);
  TWebDriverBiDiMessageEvent = reference to procedure(const Msg: string);
  TWebDriverBiDiConsoleMessageEvent = reference to procedure(const ConsoleMessage: TWebDriverConsoleMessage);
  TWebDriverWebSocketMessageEvent = procedure(Sender: TObject; const Msg: string) of object;
  TWebDriverWebSocketBasicEvent = procedure(Sender: TObject) of object;

  EWebDriverError = class(Exception);

  TWebDriverTimeoutsConfig = record
    Script: Integer;
    PageLoad: Integer;
    Implicit: Integer;
  end;

  TWebDriverProxy = record
    Host: string;
    Port: Integer;
    Username: string;
    Password: string;
    EnableProxy: Boolean;
  end;

  TWebDriverActionItemType = (MouseMove, MouseDown, MouseUp, Click, DoubleClick, KeyDown, KeyUp, Pause, ContextClick);

  TWebDriverActionItem = record
    ActionType: TWebDriverActionItemType;
    ElementId: string;
    Key: string;
    X, Y: Integer;
  end;

  TWebDriverBrowser = (wdbUnknown, wdbChrome, wdbFirefox, wdbEdge, wdbOpera, wdbBrave);
  TWebDriverBrowserHelper = record Helper for TWebDriverBrowser
    function Name : String;
    function DriverName : String;
  end;

  TWebDriverConfig = record
    Browser: TWebDriverBrowser;
    DriverPath: string;
    BrowserPath: string;
    ServerPort: Integer;
  end;

  TWebDriverCookie = record
    Name: string;
    Value: string;
    Domain: string;
    Path: string;
    Secure: Boolean;
    HttpOnly: Boolean;
    Expiry: Int64;
  end;

  TBy = record
    Strategy: string;
    Value: string;
    class function Name(const AValue: string): TBy; static;
    class function Id(const AValue: string): TBy; static;
    class function ClassName(const AValue: string): TBy; static;
    class function CssSelector(const AValue: string): TBy; static;
    class function XPath(const AValue: string): TBy; static;
    class function Css(const AValue: string): TBy; static;
    class function TagName(const AValue: string): TBy; static;
    class function LinkText(const AValue: string): TBy; static;
    class function PartialLinkText(const AValue: string): TBy; static;
    class function Attribute(const Attr, Value: string): TBy; static;
    class function FormByAction(const AValue: string): TBy; static;
    function ToJson: TJSONObject;
  end;

implementation

{ TBy }

function TBy.ToJson: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('using', Strategy);
  Result.AddPair('value', Value);
end;

class function TBy.Css(const AValue: string): TBy;
begin
  Result.Strategy := 'css selector';
  Result.Value := AValue;
end;

class function TBy.XPath(const AValue: string): TBy;
begin
  Result.Strategy := 'xpath';
  Result.Value := AValue;
end;

class function TBy.CssSelector(const AValue: string): TBy;
begin
  Result.Strategy := 'css selector';
  Result.Value := AValue;
end;

class function TBy.Name(const AValue: string): TBy;
begin
  Result.Strategy := 'css selector';
  Result.Value := '[name="' + AValue.Trim + '"]';
end;

class function TBy.Id(const AValue: string): TBy;
begin
  Result.Strategy := 'css selector';
  Result.Value := '#' + AValue.Trim;
end;

class function TBy.ClassName(const AValue: string): TBy;
var
  Trimmed: string;
  Parts: TArray<string>;
  Part, Selector: string;
begin
  Trimmed := AValue.Trim;
  Parts := Trimmed.Split([' '], TStringSplitOptions.ExcludeEmpty);

  if Length(Parts) = 0 then
    raise EWebDriverError.Create('ClassName cannot be empty.');

  Selector := '';
  for Part in Parts do
    Selector := Selector + '.' + Part;

  Result.Strategy := 'css selector';
  Result.Value := Selector;
end;

class function TBy.TagName(const AValue: string): TBy;
begin
  Result.Strategy := 'tag name';
  Result.Value    := AValue;
end;

class function TBy.LinkText(const AValue: string): TBy;
begin
  Result.Strategy := 'link text';
  Result.Value    := AValue;
end;

class function TBy.PartialLinkText(const AValue: string): TBy;
begin
  Result.Strategy := 'partial link text';
  Result.Value    := AValue;
end;

class function TBy.Attribute(const Attr, Value: string): TBy;
begin
  Result.Strategy := 'xpath';
  Result.Value := '//*[@' + Attr + '="' + Value + '"]';
end;

class function TBy.FormByAction(const AValue: string): TBy;
begin
  Result.Strategy := 'css selector';
  Result.Value := 'form[action="' + AValue + '"]';
end;

{ TWebDriverBrowserHelper }

function TWebDriverBrowserHelper.DriverName: String;
{$IFDEF MSWINDOWS}
const
  EXT = '.exe';
{$ELSE}
const
  EXT = '';
{$ENDIF}
begin
  case Self of
    wdbChrome  : Result := 'chromedriver'   + EXT;
    wdbFirefox : Result := 'geckodriver'    + EXT;
    wdbEdge    : Result := 'msedgedriver'   + EXT;
    wdbOpera   : Result := 'operadriver'    + EXT;
    wdbBrave   : Result := 'chromedriver'   + EXT;
  end;
end;

function TWebDriverBrowserHelper.Name: String;
begin
  case Self of
    wdbChrome  : Result := 'chrome';
    wdbFirefox : Result := 'firefox';
    wdbEdge    : Result := 'MicrosoftEdge';
    wdbOpera   : Result := 'opera';
    wdbBrave   : Result := 'chrome';
  end;
end;

{ TTWebDriverConsoleLogLevelHelper }

class function TWebDriverConsoleLogLevelHelper.ToConsoleLogLevel(const Str: string): TWebDriverConsoleLogLevel;
begin
  if SameText(Str, 'verbose') then
    Result := cllVerbose
  else if SameText(Str, 'debug') or SameText(Str, 'debug') then
    Result := cllDebug
  else if SameText(Str, 'info') or SameText(Str, 'info') then
    Result := cllInfo
  else if SameText(Str, 'log') or SameText(Str, 'log') then
    Result := cllLog
  else if SameText(Str, 'warning') or SameText(Str, 'warn') then
    Result := cllWarning
  else if SameText(Str, 'error') or SameText(Str, 'error') then
    Result := cllError
  else if SameText(Str, 'critical') or SameText(Str, 'fatal') then
    Result := cllCritical
  else
    Result := cllLog;
end;

function TWebDriverConsoleLogLevelHelper.ToString: string;
begin
  case Self of
    cllVerbose: Result := 'verbose';
    cllDebug: Result := 'debug';
    cllInfo: Result := 'info';
    cllLog: Result := 'log';
    cllWarning: Result := 'warning';
    cllError: Result := 'error';
    cllCritical: Result := 'critical';
  else
    Result := 'log';
  end;
end;

{ TWebDriverConsoleMethodHelper }

class function TWebDriverConsoleMethodHelper.ToConsoleMethod(const Str: string): TWebDriverConsoleMethod;
begin
  if SameText(Str, 'log') then
    Result := cmLog
  else if SameText(Str, 'debug') then
    Result := cmDebug
  else if SameText(Str, 'info') then
    Result := cmInfo
  else if SameText(Str, 'warn') or SameText(Str, 'warning') then
    Result := cmWarn
  else if SameText(Str, 'error') then
    Result := cmError
  else if SameText(Str, 'assert') then
    Result := cmAssert
  else if SameText(Str, 'trace') then
    Result := cmTrace
  else if SameText(Str, 'clear') then
    Result := cmClear
  else if SameText(Str, 'dir') then
    Result := cmDir
  else if SameText(Str, 'dirxml') then
    Result := cmDirXML
  else if SameText(Str, 'table') then
    Result := cmTable
  else if SameText(Str, 'group') then
    Result := cmGroup
  else if SameText(Str, 'groupCollapsed') then
    Result := cmGroupCollapsed
  else if SameText(Str, 'groupEnd') then
    Result := cmGroupEnd
  else if SameText(Str, 'count') then
    Result := cmCount
  else if SameText(Str, 'countReset') then
    Result := cmCountReset
  else if SameText(Str, 'time') then
    Result := cmTime
  else if SameText(Str, 'timeLog') then
    Result := cmTimeLog
  else if SameText(Str, 'timeEnd') then
    Result := cmTimeEnd
  else if SameText(Str, 'timeStamp') then
    Result := cmTimeStamp
  else if SameText(Str, 'profile') then
    Result := cmProfile
  else if SameText(Str, 'profileEnd') then
    Result := cmProfileEnd
  else if SameText(Str, 'memory') then
    Result := cmMemory
  else
    Result := cmUnknown;
end;

function TWebDriverConsoleMethodHelper.ToString: string;
begin
  case Self of
    cmLog: Result := 'log';
    cmDebug: Result := 'debug';
    cmInfo: Result := 'info';
    cmWarn: Result := 'warn';
    cmError: Result := 'error';
    cmAssert: Result := 'assert';
    cmTrace: Result := 'trace';
    cmClear: Result := 'clear';
    cmDir: Result := 'dir';
    cmDirXML: Result := 'dirxml';
    cmTable: Result := 'table';
    cmGroup: Result := 'group';
    cmGroupCollapsed: Result := 'groupCollapsed';
    cmGroupEnd: Result := 'groupEnd';
    cmCount: Result := 'count';
    cmCountReset: Result := 'countReset';
    cmTime: Result := 'time';
    cmTimeLog: Result := 'timeLog';
    cmTimeEnd: Result := 'timeEnd';
    cmTimeStamp: Result := 'timeStamp';
    cmProfile: Result := 'profile';
    cmProfileEnd: Result := 'profileEnd';
    cmMemory: Result := 'memory';
  else
    Result := 'unknown';
  end;
end;

{ TWebDriverLogSourceTypeHelper }

class function TWebDriverLogSourceTypeHelper.ToLogSourceType(const Str: string): TWebDriverLogSourceType;
begin
  if SameText(Str, 'xml') then
    Result := lstXML
  else if SameText(Str, 'javascript') or SameText(Str, 'js') then
    Result := lstJavaScript
  else if SameText(Str, 'network') then
    Result := lstNetwork
  else if SameText(Str, 'console-api') or SameText(Str, 'console') then
    Result := lstConsoleAPI
  else if SameText(Str, 'storage') then
    Result := lstStorage
  else if SameText(Str, 'appcache') or SameText(Str, 'app-cache') then
    Result := lstAppCache
  else if SameText(Str, 'rendering') then
    Result := lstRendering
  else if SameText(Str, 'security') then
    Result := lstSecurity
  else if SameText(Str, 'deprecation') then
    Result := lstDeprecation
  else if SameText(Str, 'worker') then
    Result := lstWorker
  else if SameText(Str, 'violation') then
    Result := lstViolation
  else if SameText(Str, 'intervention') then
    Result := lstIntervention
  else if SameText(Str, 'recommendation') or SameText(Str, 'recommend') then
    Result := lstRecommendation
  else
    Result := lstOther;
end;

function TWebDriverLogSourceTypeHelper.ToString: string;
begin
  case Self of
    lstXML: Result := 'xml';
    lstJavaScript: Result := 'javascript';
    lstNetwork: Result := 'network';
    lstConsoleAPI: Result := 'console-api';
    lstStorage: Result := 'storage';
    lstAppCache: Result := 'appcache';
    lstRendering: Result := 'rendering';
    lstSecurity: Result := 'security';
    lstDeprecation: Result := 'deprecation';
    lstWorker: Result := 'worker';
    lstViolation: Result := 'violation';
    lstIntervention: Result := 'intervention';
    lstRecommendation: Result := 'recommendation';
  else
    Result := 'other';
  end;
end;

end.

