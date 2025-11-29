{
  ------------------------------------------------------------------------------
  Author: ABDERRAHMANE
  Github: https://github.com/DA213/DelphiWebDriver
  ------------------------------------------------------------------------------
}

unit DelphiWebDriver.Element;

interface

uses
  System.JSON,
  System.Types,
  System.Generics.Collections,
  System.StrUtils,
  System.SysUtils,
  DelphiWebDriver.Interfaces,
  DelphiWebDriver.Types;

type
  TWebElement = class(TInterfacedObject, IWebElement)
  private
    FDriver: IWebDriver;
    FElementId: string;
  public
    constructor Create(ADriver: IWebDriver; const AElementId: string);
    function GetElementId: string;
    procedure Click;
    procedure Clear;
    procedure SendKeys(const Text: string);
    procedure Submit;
    function GetText: string;
    function GetAttribute(const Attr: string): string;
    function GetProperty(const Prop: string): string;
    function GetDomAttribute(const Attr: string): string;
    function GetDomProperty(const Prop: string): string;
    function GetCssValue(const Name: string): string;
    function IsDisplayed: Boolean;
    function IsEnabled: Boolean;
    function IsSelected: Boolean;
    function GetLocation: TPoint;
    function GetSize: TSize;
    function GetRect: TRect;
    function FindElement(By: TBy): IWebElement;
    function FindElements(By: TBy): TArray<IWebElement>;
    procedure ScrollIntoView(BehaviorSmooth: Boolean = False);
    procedure SelectByIndex(Index: Integer);
    procedure SelectByValue(const Value: string);
    procedure SelectByText(const Text: string);
  end;

implementation

{ TWebElement }

constructor TWebElement.Create(ADriver: IWebDriver; const AElementId: string);
begin
  inherited Create;
  FDriver := ADriver;
  FElementId := AElementId;
end;

function TWebElement.GetElementId: string;
begin
  Result := FElementId;
end;

procedure TWebElement.ScrollIntoView(BehaviorSmooth: Boolean);
var
  Script: string;
  Params: TJSONObject;
  ArrayArgs: TJSONArray;
  ElementObj: TJSONObject;
begin
  Script :=
    'arguments[0].scrollIntoView({' +
    'behavior: "' + IfThen(BehaviorSmooth, 'smooth', 'auto') + '",' +
    'block: "center",' +
    'inline: "nearest"' +
    '});';
  Params := TJSONObject.Create;
  ElementObj := TJSONObject.Create;
  ArrayArgs := TJSONArray.Create;
  try
    ElementObj.AddPair('ELEMENT', FElementId);
    ElementObj.AddPair('element-6066-11e4-a52e-4f735466cecf', FElementId);
    ArrayArgs.Add(ElementObj);
    Params.AddPair('script', Script);
    Params.AddPair('args', ArrayArgs);
    FDriver.Classic.Commands.SendCommand(
      'POST',
      '/session/' + FDriver.Sessions.GetSessionId + '/execute/sync',
      Params
    ).Free;
  finally
    Params.Free;
  end;
end;

procedure TWebElement.Click;
var
  Body: TJSONObject;
begin
  Body := TJSONObject.Create;
  try
    FDriver.Classic.Commands.SendCommand('POST',
      '/session/' + FDriver.Sessions.GetSessionId +
      '/element/' + FElementId + '/click',
      Body
    ).Free;
  finally
    Body.Free;
  end;
end;

procedure TWebElement.Clear;
var
  Body: TJSONObject;
begin
  Body := TJSONObject.Create;
  try
    if FDriver.BrowserConfig.Browser = wdbOpera then
      Body.AddPair('id', FElementId);

    FDriver.Classic.Commands.SendCommand(
      'POST',
      '/session/' + FDriver.Sessions.GetSessionId +
      '/element/' + FElementId + '/clear',
      Body
    ).Free;

  finally
    Body.Free;
  end;
end;

procedure TWebElement.SelectByIndex(Index: Integer);
var
  Options: TArray<IWebElement>;
begin
  Options := FindElements(TBy.TagName('option'));
  if (Index < 0) or (Index >= Length(Options)) then
    (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebElement.SelectByIndex] : index %d out of bounds ' + Index.ToString);
  Options[Index].Click;
end;

procedure TWebElement.SelectByText(const Text: string);
var
  Options: TArray<IWebElement>;
  Opt: IWebElement;
begin
  Options := FindElements(TBy.TagName('option'));
  for Opt in Options do
    if Trim(Opt.GetText) = Trim(Text) then
    begin
      Opt.Click;
      Exit;
    end;
  (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebElement.SelectByText] : no option with text ' + Text);
end;

procedure TWebElement.SelectByValue(const Value: string);
var
  Options: TArray<IWebElement>;
  Opt: IWebElement;
begin
  Options := FindElements(TBy.TagName('option'));
  for Opt in Options do
    if Opt.GetAttribute('value') = Value then
    begin
      Opt.Click;
      Exit;
    end;
  (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebElement.SelectByValue] : no option value ' + Value);
end;

procedure TWebElement.SendKeys(const Text: string);
var
  W3CBody: TJSONObject;
  JsonWireBody: TJSONObject;
  ValArray: TJSONArray;
  Ch: Char;
begin
  W3CBody := TJSONObject.Create;
  W3CBody.AddPair('text', Text);

  JsonWireBody := TJSONObject.Create;
  ValArray := TJSONArray.Create;

  for Ch in Text do
    ValArray.Add(string(Ch));

  JsonWireBody.AddPair('value', ValArray);
  try
    if FDriver.BrowserConfig.Browser = wdbOpera then
    begin
      FDriver.Classic.Commands.SendCommand(
        'POST',
        '/session/' + FDriver.Sessions.GetSessionId +
        '/element/' + FElementId + '/value',
        JsonWireBody
      ).Free;
    end
    else
    begin
      FDriver.Classic.Commands.SendCommand(
        'POST',
        '/session/' + FDriver.Sessions.GetSessionId +
        '/element/' + FElementId + '/value',
        W3CBody
      ).Free;
    end;
  finally
    W3CBody.Free;
    JsonWireBody.Free;
  end;
end;

procedure TWebElement.Submit;
var
  JSON : TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    FDriver.Classic.Commands.SendCommand('POST',
      '/session/' + FDriver.Sessions.GetSessionId + '/element/' + FElementId + '/submit',
      JSON
    ).Free;
  finally
    JSON.Free;
  end;
end;

function TWebElement.GetText: string;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/element/' + FElementId + '/text'
  );
  try
    Result := JSON.GetValue<string>('value');
  finally
    JSON.Free;
  end;
end;

function TWebElement.GetAttribute(const Attr: string): string;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/element/' + FElementId +
    '/attribute/' + Attr
  );
  try
    Result := JSON.GetValue<string>('value');
  finally
    JSON.Free;
  end;
end;

function TWebElement.GetDomAttribute(const Attr: string): string;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/element/' + FElementId +
    '/attribute/' + Attr
  );
  try
    Result := JSON.GetValue<string>('value');
  finally
    JSON.Free;
  end;
end;

function TWebElement.GetProperty(const Prop: string): string;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/element/' + FElementId +
    '/property/' + Prop
  );
  try
    Result := JSON.GetValue<string>('value');
  finally
    JSON.Free;
  end;
end;

function TWebElement.GetDomProperty(const Prop: string): string;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/element/' + FElementId +
    '/property/' + Prop
  );
  try
    Result := JSON.GetValue<string>('value');
  finally
    JSON.Free;
  end;
end;

function TWebElement.GetCssValue(const Name: string): string;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/element/' + FElementId +
    '/css/' + Name
  );
  try
    Result := JSON.GetValue<string>('value');
  finally
    JSON.Free;
  end;
end;

function TWebElement.IsDisplayed: Boolean;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/element/' + FElementId +
    '/displayed'
  );
  try
    Result := JSON.GetValue<Boolean>('value');
  finally
    JSON.Free;
  end;
end;

function TWebElement.IsEnabled: Boolean;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/element/' + FElementId +
    '/enabled'
  );
  try
    Result := JSON.GetValue<Boolean>('value');
  finally
    JSON.Free;
  end;
end;

function TWebElement.IsSelected: Boolean;
var
  JSON: TJSONValue;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/element/' + FElementId +
    '/selected'
  );
  try
    Result := JSON.GetValue<Boolean>('value');
  finally
    JSON.Free;
  end;
end;

function TWebElement.GetRect: TRect;
var
  JSON: TJSONValue;
  Obj: TJSONObject;
begin
  JSON := FDriver.Classic.Commands.SendCommand('GET',
    '/session/' + FDriver.Sessions.GetSessionId + '/element/' + FElementId + '/rect'
  );
  try
    Obj := JSON.GetValue<TJSONObject>('value');
    Result := TRect.Create(
      Obj.GetValue<Integer>('x'),
      Obj.GetValue<Integer>('y'),
      Obj.GetValue<Integer>('x') + Obj.GetValue<Integer>('width'),
      Obj.GetValue<Integer>('y') + Obj.GetValue<Integer>('height')
    );
  finally
    JSON.Free;
  end;
end;

function TWebElement.GetLocation: TPoint;
var
  R: TRect;
begin
  R := GetRect;
  Result := Point(R.Left, R.Top);
end;

function TWebElement.GetSize: TSize;
var
  R: TRect;
begin
  R := GetRect;
  Result := TSize.Create(R.Width, R.Height);
end;

function TWebElement.FindElement(By: TBy): IWebElement;
var
  Body: TJSONObject;
  LRes: TJSONValue;
  ValObj: TJSONObject;
  ElemId: string;
begin
  Body := TJSONObject.Create;
  try
    Body.AddPair('using', By.Strategy);
    Body.AddPair('value', By.Value);

    LRes := FDriver.Classic.Commands.SendCommand(
      'POST',
      '/session/' + FDriver.Sessions.GetSessionId + '/element',
      Body
    );

    try
      if LRes.TryGetValue<TJSONObject>('value', ValObj) then
      begin
        if ValObj.TryGetValue<string>(
            'element-6066-11e4-a52e-4f735466cecf', ElemId) then
          Exit(TWebElement.Create(FDriver, ElemId));

        if ValObj.TryGetValue<string>('ELEMENT', ElemId) then
          Exit(TWebElement.Create(FDriver, ElemId));
      end;

      if LRes.TryGetValue<string>('element-6066-11e4-a52e-4f735466cecf', ElemId) then
        Exit(TWebElement.Create(FDriver, ElemId));

      if LRes.TryGetValue<string>('ELEMENT', ElemId) then
        Exit(TWebElement.Create(FDriver, ElemId));

      (FDriver.Events as IWebDriverEventsInternal).TriggerError('[TWebElement.FindElement] : Cannot extract element ID: ' + LRes.ToString);
    finally
      LRes.Free;
    end;

  finally
    Body.Free;
  end;
end;

function TWebElement.FindElements(By: TBy): TArray<IWebElement>;
var
  Body: TJSONObject;
  LRes: TJSONValue;
  Arr: TJSONArray;
  Item: TJSONValue;
  ElemObj: TJSONObject;
  ElemId: string;
  List: TList<IWebElement>;
begin
  Body := TJSONObject.Create;
  List := TList<IWebElement>.Create;
  try
    Body.AddPair('using', By.Strategy);
    Body.AddPair('value', By.Value);
    LRes := FDriver.Classic.Commands.SendCommand(
      'POST',
      '/session/' + FDriver.Sessions.GetSessionId + '/elements',
      Body
    );
    try
      Arr := LRes.GetValue<TJSONArray>('value');
      if (Arr = nil) or (Arr.Count = 0) then
      begin
        Result := [];
        Exit;
      end;
      for Item in Arr do
      begin
        ElemObj := Item as TJSONObject;
        if not ElemObj.TryGetValue<string>(
            'element-6066-11e4-a52e-4f735466cecf', ElemId) then
          ElemId := ElemObj.GetValue<string>('ELEMENT');
        List.Add(TWebElement.Create(FDriver, ElemId));
      end;
      Result := List.ToArray;
    finally
      LRes.Free;
    end;
  finally
    Body.Free;
    List.Free;
  end;
end;

end.

