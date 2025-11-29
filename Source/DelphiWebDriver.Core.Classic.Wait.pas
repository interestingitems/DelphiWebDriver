{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Core.Classic.Wait;

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.JSON,
  System.DateUtils,
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebDriverWait = class(TInterfacedObject, IWebDriverWait)
  private
    [weak]
    FDriver: IWebDriver;
  public
    constructor Create(ADriver: IWebDriver);
    function UntilElement(By: TBy; TimeoutMS: Integer = 5000; IntervalMS: Integer = 200): IWebElement;
    function UntilElements(By: TBy; TimeoutMS: Integer = 5000; IntervalMS: Integer = 200): TArray<IWebElement>;
    procedure UntilPageLoad(TimeoutMS: Integer = 10000);
    function UntilElementDisappears(By: TBy; TimeoutMS: Integer = 5000; IntervalMS: Integer = 200): Boolean;
    function UntilUrlContains(const Text: string; TimeoutMS: Integer = 5000): Boolean;
    function UntilUrlIs(const Value: string; TimeoutMS: Integer = 5000): Boolean;
    function UntilTitleIs(const Value: string; TimeoutMS: Integer = 5000): Boolean;
    function UntilTitleContains(const Text: string; TimeoutMS: Integer = 5000): Boolean;
    function UntilElementTextIs(By: TBy; const Expected: string; TimeoutMS: Integer = 5000; IntervalMS: Integer = 200): Boolean;
    function UntilElementTextContains(By: TBy; const Expected: string; TimeoutMS: Integer = 5000; IntervalMS: Integer = 200): Boolean;
  end;

implementation

{ TWebDriverWait }

constructor TWebDriverWait.Create(ADriver: IWebDriver);
begin
  inherited Create;
  FDriver := ADriver;
end;

function TWebDriverWait.UntilUrlContains(const Text: string; TimeoutMS: Integer): Boolean;
var
  Start: TDateTime;
begin
  Start := Now;
  while MilliSecondsBetween(Now, Start) < TimeoutMS do
  begin
    try
      if FDriver.Classic.Navigation.GetCurrentUrl.ToLower.Contains(Text.ToLower) then
        Exit(True);
    except
    end;
    Sleep(100);
  end;
  Result := False;
end;

function TWebDriverWait.UntilUrlIs(const Value: string; TimeoutMS: Integer): Boolean;
var
  Start: TDateTime;
begin
  Start := Now;
  while MilliSecondsBetween(Now, Start) < TimeoutMS do
  begin
    try
      if SameText(FDriver.Classic.Navigation.GetCurrentUrl, Value) then
        Exit(True);
    except
    end;
    Sleep(100);
  end;
  Result := False;
end;

function TWebDriverWait.UntilTitleIs(const Value: string; TimeoutMS: Integer): Boolean;
var
  Start: TDateTime;
begin
  Start := Now;
  while MilliSecondsBetween(Now, Start) < TimeoutMS do
  begin
    try
      if SameText(FDriver.Classic.Navigation.GetTitle, Value) then
        Exit(True);
    except
    end;
    Sleep(100);
  end;
  Result := False;
end;

function TWebDriverWait.UntilTitleContains(const Text: string; TimeoutMS: Integer): Boolean;
var
  Start: TDateTime;
begin
  Start := Now;
  while MilliSecondsBetween(Now, Start) < TimeoutMS do
  begin
    try
      if FDriver.Classic.Navigation.GetTitle.ToLower.Contains(Text.ToLower) then
        Exit(True);
    except
    end;

    Sleep(100);
  end;
  Result := False;
end;

function TWebDriverWait.UntilElementDisappears(By: TBy; TimeoutMS, IntervalMS: Integer): Boolean;
var
  StartTime: TDateTime;
begin
  StartTime := Now;
  while MilliSecondsBetween(Now, StartTime) < TimeoutMS do
  begin
    try
      if not FDriver.Classic.Elements.ElementExists(By) then
      begin
        Result := True;
        Exit;
      end;
    except
    end;
    Sleep(IntervalMS);
  end;
  Result := False;
end;

function TWebDriverWait.UntilElement(By: TBy; TimeoutMS, IntervalMS: Integer): IWebElement;
var
  ElemTemp: IWebElement;
  StartTime: TDateTime;
begin
  ElemTemp := nil;
  StartTime := Now;
  while MilliSecondsBetween(Now, StartTime) < TimeoutMS do
  begin
    try
      ElemTemp := FDriver.Classic.Elements.FindElement(By);
      if Assigned(ElemTemp) then
      begin
        Result := ElemTemp;
        Exit;
      end;
    except
      ElemTemp := nil;
    end;
    Sleep(IntervalMS);
  end;
  Result := nil;
end;

function TWebDriverWait.UntilElements(By: TBy; TimeoutMS, IntervalMS: Integer): TArray<IWebElement>;
var
  Found: TArray<IWebElement>;
  StartTime: TDateTime;
begin
  StartTime := Now;
  while MilliSecondsBetween(Now, StartTime) < TimeoutMS do
  begin
    try
      Found := FDriver.Classic.Elements.FindElements(By);
      if Length(Found) > 0 then
      begin
        Result := Found;
        Exit;
      end;
    except
      // ignore and retry
    end;
    Sleep(IntervalMS);
  end;
  SetLength(Result, 0);
end;

function TWebDriverWait.UntilElementTextContains(By: TBy; const Expected: string; TimeoutMS, IntervalMS: Integer): Boolean;
var
  StartTime: TDateTime;
  Elem: IWebElement;
  Txt: string;
begin
  StartTime := Now;
  while MilliSecondsBetween(Now, StartTime) < TimeoutMS do
  begin
    try
      Elem := FDriver.Classic.Elements.FindElement(By);
      if Assigned(Elem) then
      begin
        Txt := Elem.GetText;
        if Txt.ToLower.Contains(Expected.ToLower) then
          Exit(True);
      end;
    except
    end;
    Sleep(IntervalMS);
  end;
  Result := False;
end;

function TWebDriverWait.UntilElementTextIs(By: TBy; const Expected: string; TimeoutMS, IntervalMS: Integer): Boolean;
var
  StartTime: TDateTime;
  Elem: IWebElement;
  Txt: string;
begin
  StartTime := Now;
  while MilliSecondsBetween(Now, StartTime) < TimeoutMS do
  begin
    try
      Elem := FDriver.Classic.Elements.FindElement(By);
      if Assigned(Elem) then
      begin
        Txt := Trim(Elem.GetText);
        if SameText(Txt, Expected) then
          Exit(True);
      end;
    except
    end;
    Sleep(IntervalMS);
  end;
  Result := False;
end;

procedure TWebDriverWait.UntilPageLoad(TimeoutMS: Integer);
var
  StartTime: TDateTime;
  Resp: TJSONValue;
  ReadyState: string;
  ValueNode: TJSONValue;
begin
  StartTime := Now;
  while MilliSecondsBetween(Now, StartTime) < TimeoutMS do
  begin
    try
      Resp := FDriver.Classic.Document.ExecuteScript('return document.readyState;', []);
      try
        ReadyState := '';
        if Resp is TJSONString then
        begin
          ReadyState := TJSONString(Resp).Value;
        end
        else if Resp is TJSONObject then
        begin
          ValueNode := TJSONObject(Resp).GetValue('value');
          if ValueNode is TJSONString then
            ReadyState := TJSONString(ValueNode).Value;
        end;
      finally
        Resp.Free;
      end;
      if SameText(ReadyState, 'complete') then
        Exit;
    except
    end;
    Sleep(100);
  end;
  (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebDriverWait.UntilPageLoad] : Timeout waiting for page to finish loading.');
end;

end.
