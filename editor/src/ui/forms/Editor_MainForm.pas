unit Editor_MainForm;

{$I 'editor.inc'}

interface

uses
  Classes,
  SysUtils,
  FpJson,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  ComCtrls,
  Menus,
  laz.VirtualTrees,
  SynEdit,
  SynHighlighterJScript,
  Editor_UiTypes,
  Editor_Cfg,
  Editor_EditorFrame;

type
  TOnException = procedure(const AException: Exception);

  TEditorContext = class
  strict private
    FCfg: TCfg;
    FOnException: TOnException;
    FJsonDocument: TJSONObject;
  public
    constructor Create;
    destructor Destroy; override;

    procedure FreeJsonDocument;

    property JsonDocument: TJSONObject read FJsonDocument write FJsonDocument;
    property OnException: TOnException read FOnException write FOnException;
    property Cfg: TCfg read FCfg write FCfg;
  end;

  TMainForm = class(TForm)
    OpenDialog: TOpenDialog;
    SynJScriptSyn: TSynJScriptSyn;
    VST: TLazVirtualStringTree;
    MainMenu: TMainMenu;
    StatusBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure VSTGetNodeDataSize(Sender: TBaseVirtualTree;
                                 var NodeDataSize: integer);
    procedure VSTGetText(Sender: TBaseVirtualTree;
                         Node: PVirtualNode;
                         Column: TColumnIndex;
                         TextType: TVSTTextType;
                         var CellText: string);
    procedure VSTInitNode(Sender: TBaseVirtualTree;
                          ParentNode,
                          Node: PVirtualNode;
                          var InitialStates: TVirtualNodeInitStates);
    procedure VSTFreeNode(Sender: TBaseVirtualTree;
                          Node: PVirtualNode);
  strict private
    FEditorFrame: TEditorFrame;
    FContext: TEditorContext;
    function GetMainEditor: TSynEdit;
    procedure CreateMenu;
    procedure CreateTree;
    function CreateDocumentNode: PVirtualNode;
    function CreateInfoNode(const AParent: PVirtualNode): PVirtualNode;
    function CreatePathsNode(const AParent: PVirtualNode): PVirtualNode;
    function CreateServersNode(const AParent: PVirtualNode): PVirtualNode;
    function CreateComponentsNode(const AParent: PVirtualNode): PVirtualNode;
    function CreateTagsNode(const AParent: PVirtualNode): PVirtualNode;
    procedure ClearTree;
    procedure InitializeEditor;
    procedure ExitClick(Sender: TObject);
    procedure OpenClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure DoOnException(const InE: Exception);
  public
    procedure OpenDocument(const APath: string);
    procedure OpenDocumentUnsafe(const APath: string);
    procedure SaveDocument(const APath: string);
    property MainEditor: TSynEdit read GetMainEditor;
  end;

var
  MainForm: TMainForm;

implementation

uses
  JsonParser,
  Editor_Env,
  Editor_Fonts,
  Editor_UiUtils,
  Editor_Cfg_Ini;

{$R *.lfm}

function CreateMainMenu(const AParent: TComponent): TMenuItem;
begin
  Result := TMenuItem.Create(AParent);
  Result.Name := 'mit_Main';
  Result.Caption := 'Меню';
end;

procedure CreateMainMenuOpenItem(
  const AItem: TMenuItem;
  const AOnClick: TNotifyEvent);
var
  Item: TMenuItem;
begin
  Item := TMenuItem.Create(AItem);
  Item.Name := 'mi_Open';
  Item.Caption := 'Открыть';
  Item.OnClick := AOnClick;
  AItem.Add(Item);
end;

procedure CreateMainMenuExitItem(
  const AItem: TMenuItem;
  const AOnClick: TNotifyEvent);
var
  Item: TMenuItem;
begin
  Item := TMenuItem.Create(AItem);
  Item.Name := 'mi_Exit';
  Item.Caption := 'Выход';
  Item.OnClick := AOnClick;
  AItem.Add(Item);
end;

procedure CreateMainMenuSaveItem(
  const AItem: TMenuItem;
  const AOnClick: TNotifyEvent);
var
  Item: TMenuItem;
begin
  Item := TMenuItem.Create(AItem);
  Item.Name := 'mi_Save';
  Item.Caption := 'Сохранить';
  Item.OnClick := AOnClick;
  AItem.Add(Item);
end;

constructor TEditorContext.Create;
begin
  inherited Create;
  FCfg := nil;
  FOnException := nil;
  FJsonDocument := TJSONObject.Create;
end;

destructor TEditorContext.Destroy;
begin
  FreeAndNil(FJsonDocument);
  FOnException := nil;
  FreeAndNil(FCfg);
  inherited Destroy;
end;

procedure TEditorContext.FreeJsonDocument;
begin
  FreeAndNil(FJsonDocument);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FContext := TEditorContext.Create();
  FContext.Cfg := TIniCfg.Create(TEnv.ConfigFilepath);
  CreateMenu();
  CreateTree();
  InitializeEditor();
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FContext);
  FontUnload(TEnv.EditorFont);
end;

procedure TMainForm.VSTGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: integer);
begin
  NodeDataSize := Sizeof(TElement);
end;

procedure TMainForm.VSTGetText(Sender: TBaseVirtualTree;
                         Node: PVirtualNode;
                         Column: TColumnIndex;
                         TextType: TVSTTextType;
                         var CellText: string);
var
  P: PElement;
begin
  P := Sender.GetNodeData(Node);
  CellText := P.Caption;
end;

procedure TMainForm.VSTInitNode(Sender: TBaseVirtualTree;
                          ParentNode,
                          Node: PVirtualNode;
                          var InitialStates: TVirtualNodeInitStates);
var
  P: PElement;
begin
  P := Sender.GetNodeData(Node);
  P^.Caption := '';
  P^.id := 0;
end;

procedure TMainForm.VSTFreeNode(Sender: TBaseVirtualTree;
                                Node: PVirtualNode);
begin
end;

function TMainForm.GetMainEditor: TSynEdit;
begin
  if Assigned(FEditorFrame) then
    Result := FEditorFrame.MainEditor
  else
    Result := nil;
end;

procedure TMainForm.CreateMenu;
var
  MainMenuItem: TMenuItem;
begin
  MainMenuItem := CreateMainMenu(MainMenu);
  CreateMainMenuOpenItem(MainMenuItem, OpenClick);
  CreateMainMenuSaveItem(MainMenuItem, SaveClick);
  MainMenuItem.AddSeparator();
  CreateMainMenuExitItem(MainMenuItem, ExitClick);
  MainMenu.Items.Add(MainMenuItem);
end;

procedure TMainForm.CreateTree;
var
  Node: PVirtualNode;
  Root: PVirtualNode;
begin
  Root := CreateDocumentNode();
  Node := CreateInfoNode(Root);
  Node := CreatePathsNode(Root);
  Node := CreateServersNode(Root);
  Node := CreateTagsNode(Root);
  Node := CreateComponentsNode(Root);
end;

function TMainForm.CreateDocumentNode: PVirtualNode;
var
  Node: PVirtualNode;
  P: PElement;
begin
  if Assigned(FContext.JsonDocument) then
  begin
    Node := VST.AddChild(nil, nil);

    P := VST.GetNodeData(Node);
    if Assigned(P) then
    begin
      P^.Id := 1;
      P.Caption := 'Документ';
    end;

    Result := Node;
  end
  else
    Result := nil;
end;

function TMainForm.CreateInfoNode(const AParent: PVirtualNode): PVirtualNode;
var
  Node: PVirtualNode;
  P: PElement;
  JsonInfo: TJSONData;
begin
  JsonInfo := nil;
  if FContext.JsonDocument.Find('info', JsonInfo) then
  begin
    if Assigned(JsonInfo) then
    begin
      Node := VST.AddChild(AParent, nil);
      P := VST.GetNodeData(Node);
      if Assigned(Node) then
      begin
        P^.Id := 2;
        P^.Caption := 'Блок Info';
      end;
      Result := Node;
    end
    else
      Result := nil;
  end
  else
    Result := nil;
end;

function TMainForm.CreatePathsNode(const AParent: PVirtualNode): PVirtualNode;
var
  P: PElement;
  Node: PVirtualNode;
  JsonPaths: TJSONData;
begin
  if FContext.JsonDocument.Find('paths', JsonPaths) then
  begin
    Node := VST.AddChild(AParent, nil);
    P := VST.GetNodeData(Node);
    if Assigned(Node) then
    begin
      P^.Id := 3;
      P^.Caption := 'Блок Paths';
    end;
  end
  else
    Result := nil;
end;

function TMainForm.CreateServersNode(const AParent: PVirtualNode): PVirtualNode;
var
  P: PElement;
  Node: PVirtualNode;
  JsonServers: TJSONData;
begin
  if FContext.JsonDocument.Find('servers', JsonServers) then
  begin
    Node := VST.AddChild(AParent, nil);
    P := VST.GetNodeData(Node);
    if Assigned(Node) then
    begin
      P^.Id := 3;
      P^.Caption := 'Блок Server';
    end;
    Result := Node;
  end
  else
  begin
    Result := nil;
  end;
end;

function TMainForm.CreateComponentsNode(const AParent: PVirtualNode): PVirtualNode;
var
  P: PElement;
  Node: PVirtualNode;
  JsonComponents: TJSONData;
begin
  if FContext.JsonDocument.Find('components', JsonComponents) then
  begin
    Node := VST.AddChild(AParent, nil);
    P := VST.GetNodeData(Node);
    if Assigned(Node) then
    begin
      P^.Id := 3;
      P^.Caption := 'Блок Components';
    end;
    Result := Node;
  end
  else
  begin
    Result := nil;
  end;
end;

function TMainForm.CreateTagsNode(const AParent: PVirtualNode): PVirtualNode;
var
  P: PElement;
  Node: PVirtualNode;
  JsonTags: TJSONData;
begin
  if FContext.JsonDocument.Find('tags', JsonTags) then
  begin
    Node := VST.AddChild(AParent, nil);
    P := VST.GetNodeData(Node);
    if Assigned(Node) then
    begin
      P^.Id := 3;
      P^.Caption := 'Блок Tags';
    end;
    Result := Node;
  end
  else
    Result := nil;
end;

procedure TMainForm.ClearTree;
begin
  VST.Clear;
end;

procedure TMainForm.InitializeEditor;
begin
  FEditorFrame := TEditorFrame.Create(Self);
  FEditorFrame.Align := alClient;
  FEditorFrame.Parent := Self;
  FEditorFrame.Clear();
end;

procedure TMainForm.ExitClick(Sender: TObject);
begin
  Close();
end;

procedure TMainForm.OpenClick(Sender: TObject);
begin
  OpenDialog.Title := 'Открыть файл';
  OpenDialog.InitialDir := FContext.Cfg.LastOpenedFile;
  OpenDialog.Filter :=
    'Openapi (*.json)|*.json|Openapi (*.yaml)|*.yaml|Все файлы (*.*)|*.*';
  if OpenDialog.Execute then
    OpenDocument(OpenDialog.Filename);
end;

procedure TMainForm.SaveClick(Sender: TObject);
begin
  OpenDialog.Title := 'Сохранить файл';
  OpenDialog.InitialDir := '';
  if OpenDialog.Execute() then
    SaveDocument(OpenDialog.Filename);
end;

procedure TMainForm.DoOnException(const InE: Exception);
begin
  if Assigned(FContext.OnException) then
    FContext.OnException(InE);
end;

procedure TMainForm.OpenDocument(const APath: string);
begin
  if FileExists(APath) then
  begin
    if FileSuported(APath) then
      OpenDocumentUnsafe(APath)
    else
      ShowFileNotSuported();
  end;
end;

procedure TMainForm.OpenDocumentUnsafe(const APath: string);
var
  Stream: TStringStream;
  JsonElement: TJSONData;
begin
  FContext.Cfg.LastOpenedFile := APath;

  MainEditor.BeginUpdate();
  try
    ClearTree();
    FContext.FreeJsonDocument;
    MainEditor.ClearAll;
    try
      MainEditor.Lines.LoadFromFile(APath);
    except
      on E: Exception do
        DoOnException(E);
    end;

    Stream := TStringStream.Create('', TEncoding.Utf8.Clone);
    try
      MainEditor.Lines.SaveToStream(Stream);
      Stream.Position := 0;
      JsonElement := GetJSON(Stream);
      if Assigned(JsonElement) and JsonElement.InheritsFrom(TJSONObject) then
        FContext.JsonDocument := TJSONObject(JsonElement);
    finally
      FreeAndNil(Stream);
    end;

    CreateTree();
  finally
    MainEditor.EndUpdate;
  end;
end;

procedure TMainForm.SaveDocument(const APath: string);
begin
  FContext.Cfg.LastOpenedFile := APath;

  if not MainEditor.Lines.Text.IsEmpty then;
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
end;

end.
