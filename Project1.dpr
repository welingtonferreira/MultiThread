program Project1;

uses
  Vcl.Forms,
  GenDown in 'GenDown.pas' {frmGerenciadorDownload},
  uHistoricoDownload in 'uHistoricoDownload.pas' {frmHistoricoDownload};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmGerenciadorDownload, frmGerenciadorDownload);
  Application.CreateForm(TfrmHistoricoDownload, frmHistoricoDownload);
  Application.Run;
end.
