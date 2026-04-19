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

  end;

implementation

{$R *.lfm}

end.

