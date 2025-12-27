unit DelphiWebDriverNavigationDemo.Main;

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

          if Driver.Sessions.StartSession then
            begin
              Driver.Classic.Navigation.GoToURL('https://www.google.com');

              Driver.Classic.Wait.UntilPageLoad;

              Log('Navigation Done!');
            end;

        finally
          Driver.Sessions.Quit;
          Driver.Server.Stop;
        end;
    end);
end;

end.
