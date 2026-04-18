unit Editor_MainForm;

{$I 'editor.inc'}

interface

uses
  Classes,
  SysUtils,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  ComCtrls,
  Menus,
  laz.VirtualTrees,
  SynEdit,
  SynHighlighterJScript,
  Editor_Cfg;

type
  PElement = ^TElement;
  TElement = record
    ID: Integer;
    Caption: string;
  end;

  TOnException = procedure(const AException: Exception);

  TMainForm = class(TForm)
    MainEditor: TSynEdit;
    OpenDialog: TOpenDialog;
    SynJScriptSyn: TSynJScriptSyn;
    VST: TLazVirtualStringTree;
    MainMenu: TMainMenu;
    StatusBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure VSTGetNodeDataSize(Sender: TBaseVirtualTree;
                  var NodeDataSize: Integer);
    procedure VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
                  Column: TColumnIndex; TextType: TVSTTextType;
                  var CellText: String);
    procedure VSTInitNode(Sender: TBaseVirtualTree; ParentNode,
                  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
  strict private
    FOnException: TOnException;
    FCfg: TCfg;
    procedure CreateMenu;
    function CreateMainMenu: TMenuItem;
    procedure CreateMainMenuExitItem(const AItem: TMenuItem);
    procedure CreateMainMenuOpenItem(const AItem: TMenuItem);
    procedure CreateMainMenuSaveItem(const AItem: TMenuItem);
    procedure CreateTree;
    procedure InitializeEditor;
    procedure ExitClick(Sender: TObject);
    procedure OpenClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure DefaultOnException(const AEx: Exception);
    procedure DoOnException(const InE: Exception);
  public
    procedure OpenDocument(const APath: string);
    procedure OpenDocumentUnsafe(const APath: string);
    procedure SaveDocument(const APath: string);
    property OnException: TOnException
             read FOnException
             write FOnException;
  end;

var
  MainForm: TMainForm;

implementation

uses
  Editor_Env,
  Editor_Fonts,
  Editor_Cfg_Ini;

{$R *.lfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCfg := TIniCfg.Create(TEnv.ConfigFilepath);
  CreateMenu();
  CreateTree();
  InitializeEditor();
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FontUnload(TEnv.EditorFont);
  FreeAndNil(FCfg);
end;

procedure TMainForm.VSTGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := Sizeof(TElement);
end;

procedure TMainForm.VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  P: PElement;
begin
  P := Sender.GetNodeData(Node);
  CellText := P.Caption;
end;

procedure TMainForm.VSTInitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
var
  P: PElement;
begin
  P := Sender.GetNodeData(Node);
  P^.Caption:= '';
  P^.id := 0;
end;

procedure TMainForm.VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  //
end;

procedure TMainForm.CreateMenu;
var
  MainMenuItem: TMenuItem;
begin
  MainMenuItem := CreateMainMenu();
  CreateMainMenuOpenItem(MainMenuItem);
  CreateMainMenuSaveItem(MainMenuItem);
  MainMenuItem.AddSeparator();
  CreateMainMenuExitItem(MainMenuItem);
  MainMenu.Items.Add(MainMenuItem);
end;

function TMainForm.CreateMainMenu: TMenuItem;
begin
  Result := TMenuItem.Create(MainMenu);
  Result.Name := 'mit_Main';
  Result.Caption := 'Меню';
end;

procedure TMainForm.CreateMainMenuExitItem(const AItem: TMenuItem);
var
  Item: TMenuItem;
begin
  Item := TMenuItem.Create(AItem);
  Item.Name := 'mi_Exit';
  Item.Caption:='Выход';
  Item.OnClick := ExitClick;
  AItem.Add(Item);
end;

procedure TMainForm.CreateMainMenuOpenItem(const AItem: TMenuItem);
var
  Item: TMenuItem;
begin
  Item := TMenuItem.Create(AItem);
  Item.Name := 'mi_Open';
  Item.Caption := 'Открыть';
  Item.OnClick := OpenClick;
  AItem.Add(Item);
end;

procedure TMainForm.CreateMainMenuSaveItem(const AItem: TMenuItem);
var
  Item: TMenuItem;
begin
  Item := TMenuItem.Create(AItem);
  Item.Name := 'mi_Save';
  Item.Caption := 'Сохранить';
  Item.OnClick := SaveClick;
  AItem.Add(Item);
end;

procedure TMainForm.CreateTree;
var
  P: PElement;
  Node: PVirtualNode;
  InfoNode: PVirtualnode;
begin
  Node := VST.AddChild(nil, nil);
  P := VST.GetNodeData(Node);
  if Assigned(P) then
  begin
    P^.Id := 1;
    P.Caption := 'Документ';
  end;

  InfoNode := VST.AddChild(Node, nil);
  P := VST.GetNodeData(InfoNode);
  if Assigned(InfoNode) then
  begin
    P^.Id := 2;
    P^.Caption := 'Блок Info';
  end;

  InfoNode := VST.AddChild(Node, nil);
  P := VST.GetNodeData(InfoNode);
  if Assigned(InfoNode) then
  begin
    P^.Id := 3;
    P^.Caption := 'Блок Server';
  end;
end;

procedure TMainForm.InitializeEditor;
begin
  MainEditor.ClearAll();
end;

procedure TMainForm.ExitClick(Sender: TObject);
begin
  Close();
end;

procedure TMainForm.OpenClick(Sender: TObject);
begin
  OpenDialog.InitialDir := ExtractFilePath(ParamStr(0));
  OpenDialog.Filter:='Openapi (*.json)|*.json|Openapi (*.yaml)|*.yaml|Все файлы (*.*)|*.*';
  if OpenDialog.Execute then
    OpenDocument(OpenDialog.Filename);
end;

procedure TMainForm.SaveClick(Sender: TObject);
begin
  OpenDialog.InitialDir:= '';
  if OpenDialog.Execute() then
    SaveDocument(OpenDialog.Filename);
end;

procedure TMainForm.DefaultOnException(const AEx: Exception);
begin
  ShowMessage('Ошибка: ' + AEx.Message);
end;

procedure TMainForm.DoOnException(const InE: Exception);
begin
  if Assigned(FOnException) then
    FOnException(InE);
end;

procedure TMainForm.OpenDocument(const APath: string);
begin
  if FileExists(APath) then
    OpenDocumentUnsafe(APath);
end;

procedure TMainForm.OpenDocumentUnsafe(const APath: string);
begin
  MainEditor.BeginUpdate();
  try
    MainEditor.ClearAll;
    try
      MainEditor.Lines.LoadFromFile(APath);
    except
      on E: Exception do
        DoOnException(E);
    end;
  finally
    MainEditor.EndUpdate;
  end;
end;

procedure TMainForm.SaveDocument(const APath: string);
begin
  MainEditor.BeginUpdate();
  try
    try
      MainEditor.Lines.SaveToFile(APath);
    except
      on E: Exception do
        DoOnException(E);
    end;
  finally
    MainEditor.EndUpdate();
  end;
end;

end.

