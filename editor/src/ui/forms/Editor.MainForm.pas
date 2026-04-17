unit Editor.MainForm;

{$I 'editor.inc'}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Menus,
  laz.VirtualTrees, SynEdit;

type
  TMainForm = class(TForm)
    VST: TLazVirtualStringTree;
    MainMenu: TMainMenu;
    StatusBar: TStatusBar;
    ElementEditor: TSynEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  strict private
    procedure CreateMenu;
    function CreateMainMenu: TMenuItem;
    procedure CreateMainMenuExitItem(const AItem: TMenuItem);
    procedure CreateMainMenuOpenItem(const AItem: TMenuItem);
    procedure ExitClick(Sender: TObject);
    procedure OpenClick(Sender: TObject);
  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  CreateMenu();
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  //
end;

procedure TMainForm.CreateMenu;
var
  MainMenuItem: TMenuItem;
begin
  MainMenuItem := CreateMainMenu();
  CreateMainMenuOpenItem(MainMenuItem);
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
  Item.OnClick := nil;
  AItem.Add(Item);
end;

procedure TMainForm.ExitClick(Sender: TObject);
begin
  Close();
end;

procedure TMainForm.OpenClick(Sender: TObject);
begin

end;

end.

