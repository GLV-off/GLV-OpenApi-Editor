unit Editor_EditorFrame;

{$I 'editor.inc'}

interface

uses
  Classes,
  SysUtils,
  Forms,
  Controls,
  SynEdit;

type
  TEditorFrame = class(TFrame)
    MainEditor: TSynEdit;
  private

  public
    procedure Clear;
  end;

implementation

{$R *.lfm}

procedure TEditorFrame.Clear;
begin
  MainEditor.Clear;
end;

end.

