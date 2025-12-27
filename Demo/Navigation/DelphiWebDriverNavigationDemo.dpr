program DelphiWebDriverNavigationDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  DelphiWebDriverNavigationDemo.Main in 'DelphiWebDriverNavigationDemo.Main.pas' {MainForm};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
