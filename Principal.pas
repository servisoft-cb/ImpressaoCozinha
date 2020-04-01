unit Principal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, ACBrBase, ACBrPosPrinter,
  Vcl.Menus, JvComponentBase, JvThreadTimer, Vcl.AppEvnts, Vcl.StdCtrls,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client;

type
  TfrmImpressaoCozinhaCopa = class(TForm)
    ACBrPosPrinter: TACBrPosPrinter;
    TrayIcon: TTrayIcon;
    PopupMenu1: TPopupMenu;
    JvThreadTimer1: TJvThreadTimer;
    ApplicationEvents1: TApplicationEvents;
    MMImprimir: TMemo;
    qryConsultaImpressao: TFDQuery;
    qryConsultaImpressaoID: TIntegerField;
    qryConsultaImpressaoNUMCUPOM: TIntegerField;
    qryConsultaImpressaoNUM_CARTAO: TSmallintField;
    qryConsultaImpressaoNUM_MESA: TSmallintField;
    qryConsultaImpressaoITEM: TIntegerField;
    qryConsultaImpressaoID_PRODUTO: TIntegerField;
    qryConsultaImpressaoNOME_PRODUTO: TStringField;
    qryConsultaImpressaoREFERENCIA: TStringField;
    qryConsultaImpressaoID_GRUPO: TIntegerField;
    qryConsultaImpressaoLOCAL_IMPRESSAO: TStringField;
    qryConsultaImpressaoQTD: TFloatField;
    qryConsultaImpressaoOBSERVACAO: TStringField;
    lblText: TLabel;
    spAtualizaCupom: TFDStoredProc;
    qryConsultaImpressaoDATA_HORA_PEDIDO: TSQLTimeStampField;
    qryItemSem: TFDQuery;
    qryItemSemID: TIntegerField;
    qryItemSemITEM: TIntegerField;
    qryItemSemID_PRODUTO: TIntegerField;
    procedure JvThreadTimer1Timer(Sender: TObject);
    procedure ApplicationEvents1Minimize(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
  private
    PortaImpressora : String;
    ModeloImpressora : String;
    VelocidadeImpressao : Integer;
    Cabecalho : Boolean;
    vID_Cupom : Integer;
    procedure Imprimir;
    procedure Abrir_Consulta;
    procedure AtualizaLabel(Texto : String);
    procedure AtualizaCupomItem(ID : Integer);
    procedure ConfiguraImpressora(Tipo : String);
    procedure Abrir_Item_Sem;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmImpressaoCozinhaCopa: TfrmImpressaoCozinhaCopa;

implementation

uses
  System.IniFiles, DmdConnection, uUtilPadrao;

{$R *.dfm}

procedure TfrmImpressaoCozinhaCopa.Abrir_Consulta;
begin
  qryConsultaImpressao.Close;
  qryConsultaImpressao.Open;
end;

procedure TfrmImpressaoCozinhaCopa.Abrir_Item_Sem;
begin
  qryItemSem.Close;
  qryItemSem.ParamByName('ID').AsInteger := qryConsultaImpressaoID.AsInteger;
  qryItemSem.ParamByName('ITEM').AsInteger := qryConsultaImpressaoITEM.AsInteger;
  qryItemSem.Open;
end;

procedure TfrmImpressaoCozinhaCopa.ApplicationEvents1Minimize(Sender: TObject);
begin
Self.Hide();
  Self.WindowState := wsMinimized;
  TrayIcon.Visible := True;
  TrayIcon.Animate := True;
  TrayIcon.ShowBalloonHint;
end;

procedure TfrmImpressaoCozinhaCopa.AtualizaLabel(Texto: String);
begin
  lblText.Caption := Texto;
  lblText.Update;
  lblText.Refresh;
end;

procedure TfrmImpressaoCozinhaCopa.ConfiguraImpressora(Tipo: String);
var
  Inifile : Tinifile;
begin
  Inifile := TIniFile.Create('C:\$Servisoft\Impressora.ini');
  if Tipo = 'C' then
  begin
    PortaImpressora  := IniFile.ReadString('ACBR2','PortaCozinha','');
    ModeloImpressora := IniFile.ReadString('ACBR2','ModeloCozinha','');
    VelocidadeImpressao := StrToIntDef(IniFile.ReadString('ACBR2','BoudCozinha',''),0);
  end
  else
  begin
    PortaImpressora  := IniFile.ReadString('ACBR2','PortaCopa','');
    ModeloImpressora := IniFile.ReadString('ACBR2','ModeloCopa','');
    VelocidadeImpressao := StrToIntDef(IniFile.ReadString('ACBR2','BoudCopa',''),0);
  end;

  if ModeloImpressora = 'EPSON'      then ACBrPosPrinter.Modelo := ppEscPosEpson;
  if ModeloImpressora = 'ELGIN'      then ACBrPosPrinter.Modelo := ppEscVox;
  if ModeloImpressora = 'BEMATECH'   then ACBrPosPrinter.Modelo := ppEscBematech;
  if ModeloImpressora = 'DARUMA'     then ACBrPosPrinter.Modelo := ppEscDaruma;
  if ModeloImpressora = 'DR700'      then ACBrPosPrinter.Modelo := ppEscDaruma;
  if ModeloImpressora = 'DR800'      then ACBrPosPrinter.Modelo := ppEscDaruma;

  ACBrPosPrinter.Device.Porta := PortaImpressora;
  ACBrPosPrinter.Device.Baud := VelocidadeImpressao;
  ACBrPosPrinter.Desativar;
  JvThreadTimer1.Interval := StrToIntDef(IniFile.ReadString('ACBR2','TempoCiclo',''),10000);
end;

procedure TfrmImpressaoCozinhaCopa.AtualizaCupomItem(ID: Integer);
begin
  spAtualizaCupom.Close;
  spAtualizaCupom.ParamByName('ID_Cupom').AsInteger := ID;
  spAtualizaCupom.Execute;
end;

procedure TfrmImpressaoCozinhaCopa.Imprimir;
var
  vObs : String;
  primeiro : Boolean;
begin
  primeiro := True;
  ConfiguraImpressora(qryConsultaImpressaoLOCAL_IMPRESSAO.AsString);
  MMImprimir.Lines.Clear;
  MMImprimir.Lines.Add(' ');
  MMImprimir.Lines.Add(' ');
  if qryConsultaImpressaoLOCAL_IMPRESSAO.AsString = 'C' then
    MMImprimir.Lines.Add('</ce><e> PEDIDO COZINHA </e>')
  else
    MMImprimir.Lines.Add('</ce><e> PEDIDO COPA </e>');
  MMImprimir.Lines.Add(' ');
  MMImprimir.Lines.Add(' ');
  MMImprimir.Lines.Add('</fn>-----------------------------------------');
  MMImprimir.Lines.Add('</fn> Mesa: ' + qryConsultaImpressaoNUM_MESA.AsString);
  MMImprimir.Lines.Add('</fn> Cartao: ' + qryConsultaImpressaoNUM_CARTAO.AsString);
  MMImprimir.Lines.Add('</ae>Data: '+FormatDateTime('dd/mm/yy hh:nn:ss',Now));
  MMImprimir.Lines.Add('</fn>-----------------------------------------');
  MMImprimir.Lines.Add('</fn>Qte Descricao                                   ');
  MMImprimir.Lines.Add('</ae>'+FormatFloat('##00',qryConsultaImpressaoQTD.Value) + ' ' + qryConsultaImpressaoNOME_PRODUTO.AsString);
  MMImprimir.Lines.Add(' ');
  MMImprimir.Lines.Add(' ');
  vObs := '';
  Abrir_Item_Sem;
  while not qryItemSem.Eof do
  begin
    vObs := 'SEM ' + SQLLocate('PRODUTO', 'ID', 'NOME', qryItemSemID_PRODUTO.AsString);
    if primeiro then
      MMImprimir.Lines.Add('</fn>Obs: ' + vObs)
    else
      MMImprimir.Lines.Add('</fn>     ' + vObs);
    primeiro := False;
    qryItemSem.Next;
  end;
  MMImprimir.Lines.Add('</fn>-----------------------------------------');
  MMImprimir.Lines.Add('</ce>Data/Hora: '+FormatDateTime('dd/mm/yy hh:nn:ss',qryConsultaImpressaoDATA_HORA_PEDIDO.AsDateTime));
  MMImprimir.Lines.Add(' ');
  MMImprimir.Lines.Add(' ');
  MMImprimir.Lines.Add('</corte_parcial>');
  ACBrPosPrinter.Ativar;
  ACBrPosPrinter.LinhasEntreCupons := 2;
  ACBrPosPrinter.Imprimir(MMImprimir.Lines.Text);
  ACBrPosPrinter.Desativar;
end;

procedure TfrmImpressaoCozinhaCopa.JvThreadTimer1Timer(Sender: TObject);
begin
  TrayIcon.Animate := True;
  JvThreadTimer1.Enabled := False;
  AtualizaLabel('Abrindo Consulta!');
  Abrir_Consulta;
  AtualizaLabel('Imprimindo!');
  vID_Cupom := 0;
  while not qryConsultaImpressao.Eof do
  begin
    if vID_Cupom = qryConsultaImpressaoID.AsInteger then
      Cabecalho := True
    else
      Cabecalho := False;
    Imprimir;
    AtualizaCupomItem(qryConsultaImpressaoID.AsInteger);
    vID_Cupom := qryConsultaImpressaoID.AsInteger;
    qryConsultaImpressao.Next;
  end;
  TrayIcon.Animate := False;
  JvThreadTimer1.Enabled := True;
  AtualizaLabel('Aguardando nova Consulta');
end;

procedure TfrmImpressaoCozinhaCopa.TrayIconDblClick(Sender: TObject);
begin
  TrayIcon.Visible := False;
  Show();
  WindowState := wsNormal;
  Application.BringToFront();
end;

end.
