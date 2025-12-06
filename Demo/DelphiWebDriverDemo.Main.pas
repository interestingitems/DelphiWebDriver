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
  DelphiWebDriver.Server,
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
  BrowserConfig : TWebDriverBrowserConfig;
begin
  if ChromeRadioButton.IsChecked then
    BrowserConfig.Browser := wdbChrome;
  if FirefoxRadioButton.IsChecked then
    BrowserConfig.Browser := wdbFirefox;
  if EdgeRadioButton.IsChecked then
    BrowserConfig.Browser := wdbEdge;
  if OperaRadioButton.IsChecked then
    begin
      // for opera you have to set the opera binary file path
      BrowserConfig.Browser := wdbOpera;
      BrowserConfig.BinaryPath := 'C:\Users\<YOUR USERNAME>\AppData\Local\Programs\Opera\opera.exe';
    end;
  if BraveRadioButton.IsChecked then
    begin
      // for brave you have to set the brave binary file path + you should use the ChromeDriver binary
      BrowserConfig.Browser := wdbBrave;
      BrowserConfig.BinaryPath := 'C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe';
    end;

  if BrowserConfig.Browser = wdbUnknown then
    begin
      LogsMemo.Text := 'You must select a driver';
      Exit;
    end;

  // if you have specific path for the driver path then set it with the BrowserConfig.Browser.DriverName
  // for ex : Server := TWebDriverServer.Create('C:\drivers_folder\' + BrowserConfig.Browser.DriverName);

  TTask.run(procedure
    var
      Server: TWebDriverServer;
      Driver: IWebDriver;
    begin
      Server := TWebDriverServer.Create(BrowserConfig.Browser.DriverName);
        try
          Server.Start;
          Driver := TWebDriver.Create(BrowserConfig, 'http://localhost:9515');
            try
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

                  // Driver.BiDi.Commands.SubscribeToNetworkEvents;

                  Driver.BiDi.Commands.SubscribeToConsoleEvents;

                  Driver.Classic.Navigation.GoToURL('https://www.google.com');

                  Driver.Classic.Wait.UntilPageLoad;

                  Driver.Classic.Document.ExecuteScript(
                   'console.debug("Debug message");' +
                   'console.info("Informational message");' +
                   'console.log("Regular log message");' +
                   'console.warn("Warning message");' +
                   'console.error("Error message");'
                  );

                  Log('Done :)');
                end;

            finally
              Driver.Sessions.Quit;
            end;
        finally
          Server.Stop;
          Server.Free;
        end;
    end);
end;

end.
