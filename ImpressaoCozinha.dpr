program ImpressaoCozinha;

uses
  Vcl.Forms,
  Principal in 'Principal.pas' {frmImpressaoCozinhaCopa},
  DmdConnection in 'DmdConnection.pas' {DMConection: TDataModule},
  uUtilPadrao in 'uUtilPadrao.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDMConection, DMConection);
  Application.CreateForm(TfrmImpressaoCozinhaCopa, frmImpressaoCozinhaCopa);
  Application.Run;
end.
