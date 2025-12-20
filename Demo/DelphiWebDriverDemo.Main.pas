unit DelphiWebDriverDemo.Main;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.Threading,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.Memo;

type
  TMainForm = class(TForm)
    StartDriverButton: TButton;
    DriversRectangle: TRectangle;
    ChromeRadioButton: TRadioButton;
    FirefoxRadioButton: TRadioButton;
    EdgeRadioButton: TRadioButton;
    LogsMemo: TMemo;
    OperaRadioButton: TRadioButton;
    BraveRadioButton: TRadioButton;
    procedure StartDriverButtonClick(Sender: TObject);
  private
    { Private declarations }
    procedure Log(Msg : String);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  DelphiWebDriver.Core,
  DelphiWebDriver.Types,
  DelphiWebDriver.Interfaces;

{$R *.fmx}

procedure TMainForm.Log(Msg: String);
begin
  TThread.Synchronize(nil, procedure
    begin
      LogsMemo.Lines.Add(Msg);
    end);
end;

procedure TMainForm.StartDriverButtonClick(Sender: TObject);
var
  Config : TWebDriverConfig;
begin
  if ChromeRadioButton.IsChecked then
    begin
      Config.Browser := wdbChrome;
      Config.ServerPort := 1111;
    end;

  if FirefoxRadioButton.IsChecked then
    begin
      Config.Browser := wdbFirefox;
      Config.ServerPort := 2222;
    end;

  if EdgeRadioButton.IsChecked then
    begin
      Config.Browser := wdbEdge;
      Config.ServerPort := 3333;
    end;

  if OperaRadioButton.IsChecked then
    begin
      Config.Browser := wdbOpera;
      Config.BrowserPath := 'C:\Users\<YOUR USERNAME>\AppData\Local\Programs\Opera\opera.exe';
      Config.ServerPort := 4444;
    end;

  if BraveRadioButton.IsChecked then
    begin
      Config.Browser := wdbBrave;
      Config.BrowserPath := 'C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe';
      Config.ServerPort := 5555;
    end;

  if Config.Browser = wdbUnknown then
    begin
      LogsMemo.Text := 'You must select a driver';
      Exit;
    end;

  TTask.run(procedure
    var
      Driver: IWebDriver;
    begin
      Driver := TWebDriver.Create(Config);
        try
          Driver.Server.Start;

          Driver.Events.OnError := procedure(const Error: string)
                                   begin
                                     Log('Error : ' + Error);
                                   end;

          Driver.Events.OnBiDiMessage := procedure(const Msg: string)
                                         begin
                                           Log('BiDi Msg : ' + Msg);
                                         end;

          Driver.Events.OnBiDiConsoleMessage := procedure(const ConsoleMsg: TWebDriverConsoleMessage)
                                                begin
                                                  Log('============================');
                                                  Log('ConsoleMsg Text : ' + ConsoleMsg.Text);
                                                  Log('ConsoleMsg Level : ' + ConsoleMsg.Level.ToString);
                                                  Log('ConsoleMsg Method : ' + ConsoleMsg.Method.ToString);
                                                  Log('ConsoleMsg Timestamp : ' + datetimetostr(ConsoleMsg.Timestamp));
                                                  Log('ConsoleMsg SourceContext : ' + ConsoleMsg.SourceContext);
                                                  Log('ConsoleMsg SourceRealm : ' + ConsoleMsg.SourceRealm);
                                                  Log('ConsoleMsg SourceType : ' + ConsoleMsg.SourceType);
                                                  Log('ConsoleMsg ArgumentsText : ' + ConsoleMsg.ArgumentsText);
                                                  Log('ConsoleMsg StackTrace : ' + ConsoleMsg.StackTrace);
                                                  Log('ConsoleMsg Source : ' + ConsoleMsg.Source.ToString);
                                                  Log('ConsoleMsg LineNumber : ' + ConsoleMsg.LineNumber.ToString);
                                                  Log('ConsoleMsg ColumnNumber : ' + ConsoleMsg.ColumnNumber.ToString);
                                                  Log('ConsoleMsg URL : ' + ConsoleMsg.URL);
                                                  Log('ConsoleMsg WorkerId : ' + ConsoleMsg.WorkerId);
                                                  Log('ConsoleMsg IsInternal : ' + BoolToStr(ConsoleMsg.IsInternal, True));
                                                end;

          if Driver.Sessions.StartSession then
            begin
              if Driver.BiDi.Connect then
                begin
                  //Driver.BiDi.Commands.SubscribeToNetworkEvents;

                  Driver.BiDi.Commands.SubscribeToConsoleEvents;

                  Driver.Classic.Navigation.GoToURL('https://www.google.com');

                  Driver.Classic.Wait.UntilPageLoad;

                  Driver.Classic.Document.ExecuteAsyncScript(
                    'console.debug("Debug message");' +
                    'setTimeout(() => console.info("Informational message"), 100);' +
                    'setTimeout(() => console.log("Regular log message"), 200);' +
                    'setTimeout(() => console.warn("Warning message"), 300);' +
                    'setTimeout(() => console.error("Error message"), 400);'
                  , []).Free;

                  Log('Done :)');

                  Driver.BiDi.Disconnect;
                end;
            end;

        finally
          Driver.Sessions.Quit;
          Driver.Server.Stop;
        end;
    end);
end;

end.
