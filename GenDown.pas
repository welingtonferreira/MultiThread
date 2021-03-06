unit GenDown;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.VCLUI.Wait, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.ExtCtrls, Vcl.DBCtrls, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  IdAuthentication;

type
  TfrmGerenciadorDownload = class(TForm)
    IdHTTP1: TIdHTTP;
    Edit1: TEdit;
    btnIniciarDownload: TButton;
    ProgressBar1: TProgressBar;
    Label2: TLabel;
    SaveDialog1: TSaveDialog;
    DataSource1: TDataSource;
    Label1: TLabel;
    btnPararDowload: TButton;
    btnExibirHistoricoDownload: TButton;
    FDConnection1: TFDConnection;
    FDTable1: TFDTable;
    btnExibirMensagem: TButton;
    procedure btnIniciarDownloadClick(Sender: TObject);
    procedure IdHTTP1Work(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: Int64);
    procedure IdHTTP1WorkBegin(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: Int64);
    procedure IdHTTP1WorkEnd(ASender: TObject; AWorkMode: TWorkMode);
    procedure btnPararDowloadClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnExibirHistoricoDownloadClick(Sender: TObject);
    procedure btnExibirMensagemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

  DownloadThread = class (TThread)
  private
  URL, fileName : String;
  public constructor Create(URL, fileName : String);
    procedure Execute; override;
  end;

var
  frmGerenciadorDownload: TfrmGerenciadorDownload;

implementation

{$R *.dfm}

uses
  uHistoricoDownload;

procedure TfrmGerenciadorDownload.btnIniciarDownloadClick(Sender: TObject);
begin
  try
    if ((Edit1.Text = EmptyStr) or (Edit1.Text = 'Digite a URL do arquivo')) then
    begin
      ShowMessage('Digite uma URL'); //Mensagem de Erro caso n?o coloquem uma URL no campo
    end
    else
    begin
      SaveDialog1.Execute(); // Abre uma tela para o usu?rio selecionar o local e nome do arquivo para o Download
      DownloadThread.Create(Edit1.Text, SaveDialog1.FileName);  //Cria a Thread Download passando a URL e o Endere?o do Arquivo + Nome do Arquivo escolhido pelo usu?rio
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Erro ao iniciar o download.' + E.Message);
    end;
  end;
end;
procedure TfrmGerenciadorDownload.btnPararDowloadClick(Sender: TObject);
begin
  try
    idHTTP1.Disconnect;  //Para o Download caso o usu?rio clique no bot?o de Parar o Download
  except
    on E: Exception do
    begin
      ShowMessage('Erro ao parar o download.' + E.Message);
    end;
  end;
end;

procedure TfrmGerenciadorDownload.btnExibirHistoricoDownloadClick(Sender: TObject);
begin
  try
    frmHistoricoDownload.Show; //Exibe o form2 que cont?m os dados do banco
  except
    on E: Exception do
    begin
      ShowMessage('Erro ao exibir historico do download.' + E.Message);
    end;
  end;
end;

procedure TfrmGerenciadorDownload.btnExibirMensagemClick(Sender: TObject);
begin
  try
    Label2.Show; //Apresenta a porcentagem do Download para o usu?rio
  except
  on E: Exception do
  begin
    ShowMessage('Erro ao exibir mensagem.' + E.Message);
  end;
end;
end;

procedure TfrmGerenciadorDownload.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  try
    if idHTTP1.Connected then // Se estiver fazendo o Download e Clicarem no bot?o de fechar janela.
    begin
      if MessageDlg('Existe um Download em andamento.  Deseja sair?', //Pergunta se deseja sair
        mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrNo then
        begin  // Se o retorno for Yes
          idHTTP1.Disconnect; //Encerra o Download
          Close; //Fecha a aplica??o
        end;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Erro close query.' + E.Message);
    end;
  end;
end;

procedure TfrmGerenciadorDownload.FormCreate(Sender: TObject);
begin
  try
    FDConnection1.Params.Values['Database'] := GetCurrentDir +'\..\..\banco.db'; // Captura a pasta do execut?vel para criar o caminho do banco de dados
    FDConnection1.Connected:=True; //Faz a conex?o com o banco
    FDTable1.Active:=True; //Ativa a tabela
  except
    on E: Exception do
    begin
      ShowMessage('Erro FormCreate' + E.Message); //Mensagem de Erro de conex?o com o banco
    end;
  end;
end;

procedure TfrmGerenciadorDownload.IdHTTP1Work(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
  var x : Double;
begin
  try
    ProgressBar1.Position := AWorkCount; // Captura o progresso do Download e repassa para o ProgressBar1
    x := AWorkCount * 100 / ProgressBar1.Max; // Calcula a porcentagem do Download
    Label2.Caption := FloatToStrF(x, ffNumber, 3, 0) + ' %'; //Formata o Double para imprimir apenas casas depois da v?rgula
  except
    on E: Exception do
    begin
      ShowMessage('Erro IdHTTP1Work' + E.Message); //Mensagem de Erro de conex?o com o banco
    end;
  end;
end;

procedure TfrmGerenciadorDownload.IdHTTP1WorkBegin(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCountMax: Int64);
begin
  try
    ProgressBar1.Position := 0; //Inicializa o ProgressBar1 com 0
    ProgressBar1.Max := AWorkCountMax; //Define o valor m?ximo de acordo com o tamanho do arquivo
    Label1.caption := 'Download em andamento...'; //Exibe Download em andamento no Label1
    FDConnection1.ExecSQL('INSERT INTO LOGDOWNLOAD (URL,DATAINICIO) VALUES ("'+Edit1.Text+'",datetime("now"));');//Faz a inser??o no banco de dados com o in?cio do Download
  except
    on E: Exception do
    begin
      ShowMessage('Erro IdHTTP1WorkBegin' + E.Message); //Mensagem de Erro de conex?o com o banco
    end;
  end;
end;

procedure TfrmGerenciadorDownload.IdHTTP1WorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
  ProgressBar1.Position := ProgressBar1.Max; //Preenche a barra at? o final
  Label1.Caption := 'Download Encerrado!'; //Informa que foi encerrado o Download
  try
    FDConnection1.ExecSQL('UPDATE LOGDOWNLOAD SET DATAFIM = datetime("now") WHERE CODIGO = (SELECT MAX(CODIGO) FROM LOGDOWNLOAD)');//Atualiza a ?ltima linha da tabela com a data hora fim do Download
  except
    ShowMessage('Erro na inser??o de dados no banco!'); //Mensagem de Erro no UPDATE
  end;
end;

{ DownloadThread }

constructor DownloadThread.Create (URL, fileName : string);
begin
  inherited Create(false); //N?o herdar a fun??o Create
  self.URL := URL; //Definindo a vari?vel URL da Thread
  self.fileName := fileName; //Definindo a vari?vel fileName da Thread
end;

procedure DownloadThread.Execute;
var
  downFile: TFileStream;
begin
  downFile := TFileStream.Create(self.fileName, fmCreate); //Vari?vel recebe o arquivo criado de acordo como o usu?rio desejou
  try
    frmGerenciadorDownload.IdHTTP1.Get(self.URL, downFile); //Faz efetivamente o Download do arquivo
  except
    ShowMessage('Erro no Download do Arquivo!'); //Mensagem de Erro no Download do Arquivo
  end;
  downFile.Free; //Libera a mem?ria da vari?vel
end;

end.
