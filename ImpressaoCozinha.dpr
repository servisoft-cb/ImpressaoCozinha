program ImpressaoCozinha;

uses
  Vcl.Forms,
  Windows,
  System.Variants,
  Principal in 'Principal.pas' {frmImpressaoCozinhaCopa},
  DmdConnection in 'DmdConnection.pas' {DMConection: TDataModule},
  uUtilPadrao in 'uUtilPadrao.pas', System.SysUtils;

{$R *.res}

var
  hMapping: hwnd;
begin
  Application.Initialize;
  hMapping := CreateFileMapping(HWND($FFFFFFFF), nil, PAGE_READONLY, 0, 32, PChar(ExtractFileName(Application.ExeName)));
  if (hMapping <> Null) and (GetLastError <> 0) then
  begin
    Application.MessageBox('Aplicativo já se encontra em execução !','Atenção',MB_OK);
    Halt;
  end;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDMConection, DMConection);
  Application.CreateForm(TfrmImpressaoCozinhaCopa, frmImpressaoCozinhaCopa);
  Application.Run;
end.
